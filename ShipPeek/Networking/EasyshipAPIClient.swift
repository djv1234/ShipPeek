import Foundation

@Observable
final class EasyshipAPIClient {
    /// Both of these are plain stored properties updated through `setToken`/`signOut` rather than
    /// via `didSet`, so that `@Observable` tracks them and the views reading them stay in sync.
    private(set) var environment: EasyshipEnvironment
    private(set) var hasToken: Bool

    private static let environmentKey = "easyship.environment"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        let storedRaw = UserDefaults.standard.string(forKey: Self.environmentKey)
        let environment = storedRaw.flatMap(EasyshipEnvironment.init(rawValue:)) ?? .sandbox
        self.environment = environment
        self.hasToken = KeychainStore.token(for: environment) != nil
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = APIDateDecoding.strategy
        self.decoder = decoder

        // No `keyEncodingStrategy` on purpose: `.convertToSnakeCase` leaves `line1` as `line1`
        // (it only breaks on case boundaries, and there is no capital there), while Easyship expects
        // `line_1`. Request types spell their wire keys out explicitly instead.
        self.encoder = JSONEncoder()
    }

    func setToken(_ token: String, for newEnvironment: EasyshipEnvironment) {
        KeychainStore.setToken(token, for: newEnvironment)
        environment = newEnvironment
        UserDefaults.standard.set(newEnvironment.rawValue, forKey: Self.environmentKey)
        hasToken = KeychainStore.token(for: newEnvironment) != nil
    }

    func signOut(from signedOutEnvironment: EasyshipEnvironment) {
        KeychainStore.deleteToken(for: signedOutEnvironment)
        hasToken = KeychainStore.token(for: environment) != nil
    }

    func get<Response: Decodable>(_ path: String, query: [String: String] = [:]) async throws -> Response {
        try await send(path: path, method: "GET", query: query, body: Optional<EmptyBody>.none)
    }

    func post<Body: Encodable, Response: Decodable>(_ path: String, body: Body) async throws -> Response {
        try await send(path: path, method: "POST", query: [:], body: body)
    }

    private func send<Body: Encodable, Response: Decodable>(
        path: String,
        method: String,
        query: [String: String],
        body: Body?
    ) async throws -> Response {
        guard let token = KeychainStore.token(for: environment) else {
            throw EasyshipAPIError.missingToken
        }

        // The base URL already carries the `/2024-09` path, so strip any leading slash from the
        // component to avoid an empty path segment.
        let component = path.hasPrefix("/") ? String(path.dropFirst()) : path
        var url = environment.baseURL.appendingPathComponent(component)
        if !query.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            url = components.url!
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                request.httpBody = try encoder.encode(body)
            } catch {
                throw EasyshipAPIError.encoding(error)
            }
        }

        APIDebugLog.request(method: method, url: url, body: request.httpBody)

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw EasyshipAPIError.network(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw EasyshipAPIError.server(status: 0, message: nil)
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            APIDebugLog.response(status: httpResponse.statusCode, body: data)
            throw EasyshipAPIError.unauthorized
        default:
            APIDebugLog.response(status: httpResponse.statusCode, body: data)
            throw EasyshipAPIError.server(
                status: httpResponse.statusCode,
                message: EasyshipErrorParsing.message(from: data)
            )
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw EasyshipAPIError.decoding(error)
        }
    }
}

private struct EmptyBody: Encodable {}

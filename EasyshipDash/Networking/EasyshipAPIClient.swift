import Foundation

@Observable
final class EasyshipAPIClient {
    var environment: EasyshipEnvironment {
        didSet { UserDefaults.standard.set(environment.rawValue, forKey: Self.environmentKey) }
    }

    private static let environmentKey = "easyship.environment"
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init(session: URLSession = .shared) {
        let storedRaw = UserDefaults.standard.string(forKey: Self.environmentKey)
        self.environment = storedRaw.flatMap(EasyshipEnvironment.init(rawValue:)) ?? .sandbox
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        self.encoder = encoder
    }

    var hasToken: Bool {
        KeychainStore.token(for: environment) != nil
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

        var url = environment.baseURL.appendingPathComponent(path)
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
            request.httpBody = try? encoder.encode(body)
        }

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
            throw EasyshipAPIError.unauthorized
        default:
            let message = (try? decoder.decode(EasyshipErrorEnvelope.self, from: data))?.message
            throw EasyshipAPIError.server(status: httpResponse.statusCode, message: message)
        }

        do {
            return try decoder.decode(Response.self, from: data)
        } catch {
            throw EasyshipAPIError.decoding(error)
        }
    }
}

private struct EmptyBody: Encodable {}

private struct EasyshipErrorEnvelope: Decodable {
    let message: String?
}

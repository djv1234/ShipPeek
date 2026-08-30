import Foundation

enum EasyshipAPIError: Error, LocalizedError {
    case missingToken
    case unauthorized
    case server(status: Int, message: String?)
    case encoding(Error)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            "No API token is set. Add one in Settings."
        case .unauthorized:
            "Easyship rejected the API token. Check it — and the matching environment — in Settings."
        case .server(let status, let message):
            message.map { "Easyship (\(status)): \($0)" } ?? "Easyship returned an error (status \(status))."
        case .encoding(let error):
            "Couldn't build the request — \(error.localizedDescription)"
        case .decoding(let error):
            "Couldn't read Easyship's response — \(DecodingErrorFormatting.describe(error))"
        case .network(let error):
            error.localizedDescription
        }
    }
}

/// `DecodingError.localizedDescription` collapses to "The data couldn't be read", which says nothing
/// about *which* field disagreed with the model. Surfacing the coding path turns a schema mismatch
/// into a one-line fix instead of a debugging session.
enum DecodingErrorFormatting {
    static func describe(_ error: Error) -> String {
        guard let error = error as? DecodingError else { return error.localizedDescription }

        switch error {
        case .keyNotFound(let key, let context):
            return "missing field \"\(key.stringValue)\"\(location(context))"
        case .typeMismatch(let type, let context):
            return "expected \(type)\(location(context))"
        case .valueNotFound(let type, let context):
            return "no value for \(type)\(location(context))"
        case .dataCorrupted(let context):
            return "\(context.debugDescription)\(location(context))"
        @unknown default:
            return error.localizedDescription
        }
    }

    private static func location(_ context: DecodingError.Context) -> String {
        let path = context.codingPath.map(\.stringValue).joined(separator: ".")
        return path.isEmpty ? "" : " at \(path)"
    }
}

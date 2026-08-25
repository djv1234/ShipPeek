import Foundation

enum EasyshipAPIError: Error, LocalizedError {
    case missingToken
    case unauthorized
    case server(status: Int, message: String?)
    case decoding(Error)
    case network(Error)

    var errorDescription: String? {
        switch self {
        case .missingToken:
            "No API token is set. Add one in Settings."
        case .unauthorized:
            "Easyship rejected the API token. Check it in Settings."
        case .server(let status, let message):
            message ?? "Easyship returned an error (status \(status))."
        case .decoding:
            "Couldn't read Easyship's response. It may have changed format."
        case .network(let error):
            error.localizedDescription
        }
    }
}

import Foundation

enum EasyshipEnvironment: String, CaseIterable, Identifiable {
    case sandbox
    case production

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sandbox: "Sandbox"
        case .production: "Production"
        }
    }

    var baseURL: URL {
        switch self {
        case .sandbox:
            URL(string: "https://public-api-sandbox.easyship.com/2024-09")!
        case .production:
            URL(string: "https://public-api.easyship.com/2024-09")!
        }
    }
}

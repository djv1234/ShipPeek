import Foundation

@Observable
final class SettingsViewModel {
    let apiClient: EasyshipAPIClient

    var selectedEnvironment: EasyshipEnvironment {
        didSet { tokenInput = KeychainStore.token(for: selectedEnvironment) ?? "" }
    }
    var tokenInput: String
    var shipFromAddress: Address
    var savedConfirmation: Bool = false

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
        self.selectedEnvironment = apiClient.environment
        self.tokenInput = KeychainStore.token(for: apiClient.environment) ?? ""
        self.shipFromAddress = DefaultShipFromStore.load()
    }

    var canSave: Bool {
        !tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func saveToken() {
        let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        KeychainStore.setToken(trimmed, for: selectedEnvironment)
        apiClient.environment = selectedEnvironment
        savedConfirmation = true
    }

    func saveShipFromAddress() {
        DefaultShipFromStore.save(shipFromAddress)
        savedConfirmation = true
    }

    func signOut() {
        KeychainStore.deleteToken(for: selectedEnvironment)
        tokenInput = ""
    }
}

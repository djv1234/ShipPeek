import Foundation

@Observable
final class SettingsViewModel {
    let apiClient: EasyshipAPIClient

    var selectedEnvironment: EasyshipEnvironment
    var tokenInput: String
    var shipFromAddress: Address
    var savedConfirmation: Bool = false

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
        self.selectedEnvironment = apiClient.environment
        self.tokenInput = KeychainStore.token(for: apiClient.environment) ?? ""
        self.shipFromAddress = DefaultShipFromStore.load()
    }

    /// Sandbox and production hold separate tokens, so swapping the picker swaps which one is shown.
    /// Driven by the view's `.onChange` rather than a `didSet` on `selectedEnvironment`, which would
    /// mean giving the property accessors that `@Observable` also wants to synthesize.
    func reloadTokenForSelectedEnvironment() {
        tokenInput = KeychainStore.token(for: selectedEnvironment) ?? ""
    }

    var canSave: Bool {
        !tokenInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// The Rate Calculator can't send a request without at least a country (and a ZIP for US
    /// origins), so surface that here rather than letting the first rate request fail.
    var isShipFromComplete: Bool {
        shipFromAddress.isValidForRateRequest
    }

    func saveToken() {
        let trimmed = tokenInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        apiClient.setToken(trimmed, for: selectedEnvironment)
        savedConfirmation = true
    }

    func saveShipFromAddress() {
        DefaultShipFromStore.save(shipFromAddress)
        savedConfirmation = true
    }

    func signOut() {
        apiClient.signOut(from: selectedEnvironment)
        tokenInput = ""
    }
}

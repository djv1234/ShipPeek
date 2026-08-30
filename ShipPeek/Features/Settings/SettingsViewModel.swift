import Foundation

@Observable
final class SettingsViewModel {
    let apiClient: EasyshipAPIClient
    private let shipFromStore: ShipFromStore

    var selectedEnvironment: EasyshipEnvironment
    var tokenInput: String
    /// A working copy — edits only reach the shared store when "Save Address" is tapped.
    var shipFromAddress: Address
    var savedConfirmation: Bool = false

    init(apiClient: EasyshipAPIClient, shipFromStore: ShipFromStore = .shared) {
        self.apiClient = apiClient
        self.shipFromStore = shipFromStore
        self.selectedEnvironment = apiClient.environment
        self.tokenInput = KeychainStore.token(for: apiClient.environment) ?? ""
        self.shipFromAddress = shipFromStore.address
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
        shipFromStore.save(shipFromAddress)
        savedConfirmation = true
    }

    func signOut() {
        apiClient.signOut(from: selectedEnvironment)
        tokenInput = ""
    }
}

import Foundation

/// Persists the user's default "ship from" address (used to prefill the Rate Calculator).
enum DefaultShipFromStore {
    private static let key = "easyship.defaultShipFromAddress"

    static func load() -> Address {
        guard let data = UserDefaults.standard.data(forKey: key),
              let address = try? JSONDecoder().decode(Address.self, from: data) else {
            return .empty
        }
        return address
    }

    static func save(_ address: Address) {
        guard let data = try? JSONEncoder().encode(address) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

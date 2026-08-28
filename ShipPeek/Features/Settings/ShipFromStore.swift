import Foundation

/// The user's default "ship from" address, used as the origin of every rate request.
///
/// A shared observable object rather than a set of static accessors: the Rate Calculator and
/// Settings live in different tabs, and when this was read on demand the calculator could hold a
/// stale copy — you'd save an address in Settings and still find "Get Rates" disabled. Both screens
/// now read the same instance, so a save is visible everywhere immediately.
@Observable
final class ShipFromStore {
    static let shared = ShipFromStore()

    private static let key = "easyship.defaultShipFromAddress"

    private(set) var address: Address
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let data = userDefaults.data(forKey: Self.key),
           let stored = try? JSONDecoder().decode(Address.self, from: data) {
            self.address = stored
        } else {
            self.address = .empty
        }
    }

    func save(_ address: Address) {
        self.address = address
        guard let data = try? JSONEncoder().encode(address) else { return }
        userDefaults.set(data, forKey: Self.key)
    }
}

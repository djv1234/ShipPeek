import Foundation

/// Tracks which pieces of first-run guidance the user has already seen, so the app explains itself
/// once and then gets out of the way. Persisted, so it survives relaunches — but resettable from
/// Settings, which matters when handing a build to a new tester on the same device.
@Observable
final class WalkthroughState {
    static let shared = WalkthroughState()

    /// Identifiers for the inline coach bubbles.
    enum Tip {
        static let rateCalculator = "rateCalculator"
        static let shipFrom = "shipFrom"
        static let shipments = "shipments"
    }

    private enum Key {
        static let hasSeenWelcome = "shippeek.walkthrough.hasSeenWelcome"
        static let hasFetchedRates = "shippeek.walkthrough.hasFetchedRates"
        static let dismissedTips = "shippeek.walkthrough.dismissedTips"
    }

    private let userDefaults: UserDefaults

    private(set) var hasSeenWelcome: Bool
    private(set) var hasFetchedRates: Bool
    private(set) var dismissedTips: Set<String>

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.hasSeenWelcome = userDefaults.bool(forKey: Key.hasSeenWelcome)
        self.hasFetchedRates = userDefaults.bool(forKey: Key.hasFetchedRates)
        self.dismissedTips = Set(userDefaults.stringArray(forKey: Key.dismissedTips) ?? [])
    }

    func shouldShow(_ tip: String) -> Bool {
        !dismissedTips.contains(tip)
    }

    func dismiss(_ tip: String) {
        dismissedTips.insert(tip)
        userDefaults.set(Array(dismissedTips), forKey: Key.dismissedTips)
    }

    func markWelcomeSeen() {
        guard !hasSeenWelcome else { return }
        hasSeenWelcome = true
        userDefaults.set(true, forKey: Key.hasSeenWelcome)
    }

    /// Once a quote has come back the user has clearly found their way around, so the Rate
    /// Calculator's coaching retires itself rather than waiting to be dismissed.
    func markRatesFetched() {
        guard !hasFetchedRates else { return }
        hasFetchedRates = true
        userDefaults.set(true, forKey: Key.hasFetchedRates)
    }

    func replay() {
        hasSeenWelcome = false
        hasFetchedRates = false
        dismissedTips = []
        userDefaults.removeObject(forKey: Key.hasSeenWelcome)
        userDefaults.removeObject(forKey: Key.hasFetchedRates)
        userDefaults.removeObject(forKey: Key.dismissedTips)
    }
}

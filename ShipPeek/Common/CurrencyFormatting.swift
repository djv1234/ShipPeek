import Foundation

enum CurrencyFormatting {
    static func format(_ amount: Double?, currencyCode: String = "USD") -> String {
        guard let amount else { return "—" }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currencyCode)"
    }
}

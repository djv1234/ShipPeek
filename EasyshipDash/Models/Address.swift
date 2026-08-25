import Foundation

/// Origin/destination address as expected by the Easyship `/rates` endpoint.
struct Address: Codable, Equatable {
    var contactName: String = ""
    var companyName: String = ""
    var contactEmail: String = ""
    var contactPhone: String = ""
    var line1: String = ""
    var line2: String = ""
    var city: String = ""
    var state: String = ""
    var postalCode: String = ""
    var countryAlpha2: String = ""

    static let empty = Address()

    /// Matches Easyship's own quote tool: country is always required; postal code only for the US
    /// (many other countries either lack postal codes or don't need one for a rate estimate).
    var isValidForRateRequest: Bool {
        guard !countryAlpha2.isEmpty else { return false }
        return countryAlpha2 != "US" || !postalCode.isEmpty
    }
}

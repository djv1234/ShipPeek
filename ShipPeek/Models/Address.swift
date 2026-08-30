import Foundation

/// Origin/destination address as expected by the Easyship `/rates` endpoint.
///
/// Wire keys are spelled out rather than left to a snake-case key strategy: `line1` has no case
/// boundary for `.convertToSnakeCase` to break on, so it would go out as `line1` and Easyship —
/// which wants `line_1` — would silently drop the street lines.
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

    enum CodingKeys: String, CodingKey {
        case contactName = "contact_name"
        case companyName = "company_name"
        case contactEmail = "contact_email"
        case contactPhone = "contact_phone"
        case line1 = "line_1"
        case line2 = "line_2"
        case city
        case state
        case postalCode = "postal_code"
        case countryAlpha2 = "country_alpha2"
    }

    static let empty = Address()

    /// Matches Easyship's own quote tool: country is always required; postal code only for the US
    /// (many other countries either lack postal codes or don't need one for a rate estimate).
    var isValidForRateRequest: Bool {
        guard !countryAlpha2.isEmpty else { return false }
        return countryAlpha2 != "US" || !postalCode.isEmpty
    }
}

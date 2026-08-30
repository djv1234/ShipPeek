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

// Coding lives in an extension so the memberwise `init()` behind `Address.empty` survives —
// declaring an initializer in the type body would suppress it.
extension Address {
    /// Blank fields are **omitted** rather than sent as `""`. An empty string is not the same as an
    /// absent field to a validating API: `"contact_email": ""` fails email-format validation, and
    /// the form leaves most of these empty by design (only country and postal code are required).
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(contactName.nilIfBlank, forKey: .contactName)
        try container.encodeIfPresent(companyName.nilIfBlank, forKey: .companyName)
        try container.encodeIfPresent(contactEmail.nilIfBlank, forKey: .contactEmail)
        try container.encodeIfPresent(contactPhone.nilIfBlank, forKey: .contactPhone)
        try container.encodeIfPresent(line1.nilIfBlank, forKey: .line1)
        try container.encodeIfPresent(line2.nilIfBlank, forKey: .line2)
        try container.encodeIfPresent(city.nilIfBlank, forKey: .city)
        try container.encodeIfPresent(state.nilIfBlank, forKey: .state)
        try container.encodeIfPresent(postalCode.nilIfBlank, forKey: .postalCode)
        try container.encodeIfPresent(countryAlpha2.nilIfBlank, forKey: .countryAlpha2)
    }

    /// Mirrors the omitting encoder: any key the encoder skipped decodes back to "". Without this
    /// the synthesized decoder would throw on a missing key, and a saved ship-from address would
    /// fail to load rather than come back partially filled.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        contactName = try container.decodeIfPresent(String.self, forKey: .contactName) ?? ""
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName) ?? ""
        contactEmail = try container.decodeIfPresent(String.self, forKey: .contactEmail) ?? ""
        contactPhone = try container.decodeIfPresent(String.self, forKey: .contactPhone) ?? ""
        line1 = try container.decodeIfPresent(String.self, forKey: .line1) ?? ""
        line2 = try container.decodeIfPresent(String.self, forKey: .line2) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? ""
        postalCode = try container.decodeIfPresent(String.self, forKey: .postalCode) ?? ""
        countryAlpha2 = try container.decodeIfPresent(String.self, forKey: .countryAlpha2) ?? ""
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

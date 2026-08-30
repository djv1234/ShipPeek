import Foundation

/// Parcel payload for the `/rates` request. Units are whatever `shipping_settings.units` declares —
/// the app sends lb/in — and per Easyship's own sample the parcel-level `box` stays null while
/// dimensions live on each item.
struct Parcel: Encodable, Equatable {
    var totalActualWeight: Double
    var box: ParcelBox?
    var items: [ParcelItem]

    enum CodingKeys: String, CodingKey {
        case totalActualWeight = "total_actual_weight"
        case box
        case items
    }
}

struct ParcelBox: Encodable, Equatable {
    var length: Double
    var width: Double
    var height: Double
}

struct ParcelItem: Encodable, Equatable, Identifiable {
    var id = UUID()
    var description: String = ""
    /// Easyship requires **one of** `category` or `hs_code` on every item — a request with both
    /// blank comes back 422: "category can't be blank if hs_code is blank".
    var category: String? = nil
    /// The documented alternative to `category`: an eight-digit WTO Harmonized System code. Accepted
    /// regardless of the category enum, so it doubles as the escape hatch when a category is rejected.
    var hsCode: String? = nil
    /// Optional, like `category`, so an unset value is omitted instead of sent as `""`.
    var sku: String? = nil
    var originCountryAlpha2: String = ""
    var quantity: Int = 1
    var dimensions: ParcelBox?
    var actualWeight: Double = 0
    var declaredCurrency: String = "USD"
    var declaredCustomsValue: Double = 0

    /// The one category value confirmed to pass validation — it comes from Easyship's own generated
    /// sample request. The full enum isn't published anywhere machine-readable (the API reference
    /// renders via JavaScript), so the field is left editable rather than turned into a picker of
    /// guesses that would 422 on selection.
    static let defaultCategory = "fashion"

    enum CodingKeys: String, CodingKey {
        case description
        case category
        case hsCode = "hs_code"
        case sku
        case originCountryAlpha2 = "origin_country_alpha2"
        case quantity
        case dimensions
        case actualWeight = "actual_weight"
        case declaredCurrency = "declared_currency"
        case declaredCustomsValue = "declared_customs_value"
    }
}

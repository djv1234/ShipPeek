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
    /// Satisfies Easyship's *first* validation pass ("category can't be blank if hs_code is blank"),
    /// but is not sufficient on its own — see `itemCategoryId`. Always sent with `defaultCategory`.
    var category: String? = nil
    /// Easyship's second validation pass wants **`item_category_id` or `hs_code`**, not the plain
    /// `category` string: "Shipment items need to input either item_category_id or hs_code at least".
    /// The valid ids aren't published anywhere reachable, so `hs_code` is the path the UI leads with.
    var itemCategoryId: String? = nil
    /// Eight-digit WTO Harmonized System code (last two digits always `00`, e.g. `42029100`).
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
        case itemCategoryId = "item_category_id"
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

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
    /// Omitted from the request when nil. Easyship's working samples populate this (e.g. "fashion"),
    /// but the valid enum is unconfirmed — and leaving a field out is likelier to pass validation
    /// than sending an empty string, so this stays nil until we know the accepted values.
    var category: String? = nil
    /// Optional, like `category`, so an unset value is omitted instead of sent as `""`.
    var sku: String? = nil
    var originCountryAlpha2: String = ""
    var quantity: Int = 1
    var dimensions: ParcelBox?
    var actualWeight: Double = 0
    var declaredCurrency: String = "USD"
    var declaredCustomsValue: Double = 0

    enum CodingKeys: String, CodingKey {
        case description
        case category
        case sku
        case originCountryAlpha2 = "origin_country_alpha2"
        case quantity
        case dimensions
        case actualWeight = "actual_weight"
        case declaredCurrency = "declared_currency"
        case declaredCustomsValue = "declared_customs_value"
    }
}

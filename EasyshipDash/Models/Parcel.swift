import Foundation

/// Parcel payload for the `/rates` request. Mirrors Easyship's parcel schema
/// (total weight in kg, optional box dimensions in cm, line items with customs value).
struct Parcel: Codable, Equatable {
    var totalActualWeight: Double
    var box: ParcelBox?
    var items: [ParcelItem]
}

struct ParcelBox: Codable, Equatable {
    var length: Double
    var width: Double
    var height: Double
}

struct ParcelItem: Codable, Equatable, Identifiable {
    let id = UUID()
    var description: String = ""
    var category: String = ""
    var sku: String = ""
    var originCountryAlpha2: String = ""
    var quantity: Int = 1
    var dimensions: ParcelBox?
    var actualWeight: Double = 0
    var declaredCurrency: String = "USD"
    var declaredCustomsValue: Double = 0

    enum CodingKeys: String, CodingKey {
        case description, category, sku, originCountryAlpha2, quantity, dimensions, actualWeight, declaredCurrency, declaredCustomsValue
    }
}

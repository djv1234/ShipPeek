import Foundation

struct RatesRequest: Encodable {
    var originAddress: Address
    var destinationAddress: Address
    var parcels: [Parcel]
    var incoterms: String = "DDU"
    var insurance = Insurance(isInsured: false)
    var courierSettings = CourierSettings(showCourierLogoUrl: false, applyShippingRules: true)
    var shippingSettings: ShippingSettings
    var calculateTaxAndDuties: Bool = true
}

struct Insurance: Encodable {
    var isInsured: Bool
}

struct CourierSettings: Encodable {
    var showCourierLogoUrl: Bool
    var applyShippingRules: Bool
}

struct ShippingSettings: Encodable {
    var units: Units
}

struct Units: Encodable {
    /// "kg" or "lb"
    var weight: String
    /// "cm" or "in"
    var dimensions: String
}

struct RatesResponse: Decodable {
    let rates: [RateQuote]
}

struct RateQuote: Decodable, Identifiable, Equatable {
    var courierService: CourierService
    var totalCharge: Double?
    var shipmentCharge: Double?
    var fuelSurcharge: Double?
    var minDeliveryTime: Int?
    var maxDeliveryTime: Int?
    var incoterms: String?

    var id: String { courierService.id }
}

struct CourierService: Decodable, Identifiable, Equatable {
    var id: String
    var name: String
    var umbrellaName: String?
}

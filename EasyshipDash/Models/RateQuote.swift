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

    enum CodingKeys: String, CodingKey {
        case originAddress = "origin_address"
        case destinationAddress = "destination_address"
        case parcels
        case incoterms
        case insurance
        case courierSettings = "courier_settings"
        case shippingSettings = "shipping_settings"
        case calculateTaxAndDuties = "calculate_tax_and_duties"
    }
}

struct Insurance: Encodable {
    var isInsured: Bool

    enum CodingKeys: String, CodingKey {
        case isInsured = "is_insured"
    }
}

struct CourierSettings: Encodable {
    var showCourierLogoUrl: Bool
    var applyShippingRules: Bool

    enum CodingKeys: String, CodingKey {
        case showCourierLogoUrl = "show_courier_logo_url"
        case applyShippingRules = "apply_shipping_rules"
    }
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
    var currency: String?

    var id: String { courierService.id }
}

struct CourierService: Decodable, Identifiable, Equatable {
    var id: String
    var name: String
    var umbrellaName: String?
}

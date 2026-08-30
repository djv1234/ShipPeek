import Foundation

struct ShipmentsResponse: Decodable {
    let shipments: [Shipment]
    let meta: PaginationMeta?
}

struct PaginationMeta: Decodable {
    let pagination: PaginationInfo?
}

struct PaginationInfo: Decodable {
    let page: Int?
    /// Next page number to fetch, or nil when there are no more pages.
    let next: Int?
    let count: Int?
}

struct Shipment: Decodable, Identifiable, Equatable {
    var easyshipShipmentId: String
    var shipmentState: String?
    var deliveryState: String?
    var labelState: String?
    var courierService: CourierService?
    var trackings: [ShipmentTracking]?
    var trackingPageUrl: String?
    var createdAt: Date?
    var updatedAt: Date?

    var id: String { easyshipShipmentId }
}

struct ShipmentTracking: Decodable, Equatable {
    var trackingNumber: String?
    var handler: String?
    var trackingState: String?
}

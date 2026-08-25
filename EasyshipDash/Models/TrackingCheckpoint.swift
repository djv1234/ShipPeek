import Foundation

/// Response of `GET /shipments/trackings` — despite the endpoint being about tracking,
/// Easyship wraps results under a "shipments" key (confirmed against the live API reference).
struct ShipmentTrackingsResponse: Decodable {
    let shipments: [ShipmentTrackingDetail]
    let meta: PaginationMeta?
}

struct ShipmentTrackingDetail: Decodable {
    var easyshipShipmentId: String?
    var status: String?
    var etaDate: Date?
    var trackingPageUrl: String?
    var originCountryAlpha2: String?
    var destinationCountryAlpha2: String?
    var trackings: [ShipmentTracking]?
    var checkpoints: [TrackingCheckpoint]?
}

struct TrackingCheckpoint: Decodable, Identifiable, Equatable {
    let id = UUID()
    var checkpointTime: Date?
    var primaryStatus: String?
    var message: String?
    var city: String?
    var countryName: String?
    var handler: String?

    enum CodingKeys: String, CodingKey {
        case checkpointTime, primaryStatus, message, city, countryName, handler
    }
}

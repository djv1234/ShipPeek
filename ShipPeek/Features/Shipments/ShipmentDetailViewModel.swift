import Foundation

@Observable
final class ShipmentDetailViewModel {
    private let apiClient: EasyshipAPIClient
    let shipment: Shipment

    var tracking: ShipmentTrackingDetail?
    var isLoading = false
    var errorMessage: String?

    init(apiClient: EasyshipAPIClient, shipment: Shipment) {
        self.apiClient = apiClient
        self.shipment = shipment
    }

    @MainActor
    func loadTracking() async {
        isLoading = true
        errorMessage = nil
        do {
            let response: ShipmentTrackingsResponse = try await apiClient.get(
                "/shipments/trackings",
                query: [
                    "easyship_shipment_id[]": shipment.easyshipShipmentId,
                    "include_checkpoints": "true"
                ]
            )
            tracking = response.shipments.first
        } catch {
            errorMessage = (error as? EasyshipAPIError)?.errorDescription ?? error.localizedDescription
        }
        isLoading = false
    }
}

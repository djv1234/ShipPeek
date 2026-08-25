import SwiftUI

struct ShipmentDetailView: View {
    @State private var viewModel: ShipmentDetailViewModel

    init(apiClient: EasyshipAPIClient, shipment: Shipment) {
        _viewModel = State(initialValue: ShipmentDetailViewModel(apiClient: apiClient, shipment: shipment))
    }

    var body: some View {
        List {
            Section("Shipment") {
                LabeledContent("ID", value: viewModel.shipment.easyshipShipmentId)
                if let courier = viewModel.shipment.courierService?.name {
                    LabeledContent("Courier", value: courier)
                }
                if let state = viewModel.shipment.shipmentState {
                    LabeledContent("State", value: state.capitalized)
                }
                if let trackingNumber = viewModel.shipment.trackings?.first?.trackingNumber {
                    LabeledContent("Tracking #", value: trackingNumber)
                }
            }

            if viewModel.isLoading {
                LoadingView(message: "Loading tracking…")
                    .frame(height: 120)
            } else if let errorMessage = viewModel.errorMessage {
                ErrorBanner(message: errorMessage) {
                    Task { await viewModel.loadTracking() }
                }
                .frame(height: 160)
            } else if let tracking = viewModel.tracking {
                Section("Status") {
                    LabeledContent("Latest", value: tracking.status ?? "Unknown")
                    if let eta = tracking.etaDate {
                        LabeledContent("ETA", value: eta.formatted(date: .abbreviated, time: .omitted))
                    }
                }

                if let checkpoints = tracking.checkpoints, !checkpoints.isEmpty {
                    Section("Checkpoints") {
                        ForEach(checkpoints) { checkpoint in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(checkpoint.primaryStatus ?? checkpoint.message ?? "Update")
                                    .font(.subheadline.weight(.medium))
                                if let message = checkpoint.message, message != checkpoint.primaryStatus {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    if let city = checkpoint.city {
                                        Text(city)
                                    }
                                    if let time = checkpoint.checkpointTime {
                                        Text(time.formatted(date: .abbreviated, time: .shortened))
                                    }
                                }
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(viewModel.shipment.easyshipShipmentId)
        .task {
            await viewModel.loadTracking()
        }
    }
}

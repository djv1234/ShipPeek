import SwiftUI

struct ShipmentsListView: View {
    let apiClient: EasyshipAPIClient
    @State private var viewModel: ShipmentsListViewModel
    private let walkthrough = WalkthroughState.shared

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
        _viewModel = State(initialValue: ShipmentsListViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if walkthrough.shouldShow(WalkthroughState.Tip.shipments) {
                    CoachBubble(
                        text: "Everything already booked on your Easyship account shows up here. Pull down to refresh, filter by state from the toolbar, and tap any shipment for checkpoint-level tracking."
                    ) {
                        walkthrough.dismiss(WalkthroughState.Tip.shipments)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                content
            }
            .navigationTitle("Shipments")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu("Filter") {
                        Button("All") {
                            Task { await viewModel.select(state: nil) }
                        }
                        ForEach(ShipmentsListViewModel.states, id: \.self) { state in
                            Button(state.capitalized) {
                                Task { await viewModel.select(state: state) }
                            }
                        }
                    }
                }
            }
            .task {
                if viewModel.shipments.isEmpty { await viewModel.reload() }
            }
            .refreshable {
                await viewModel.reload()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.shipments.isEmpty, viewModel.isLoading {
            LoadingView(message: "Loading shipments…")
        } else if let errorMessage = viewModel.errorMessage, viewModel.shipments.isEmpty {
            ErrorBanner(message: errorMessage) {
                Task { await viewModel.reload() }
            }
        } else if viewModel.shipments.isEmpty {
            ContentUnavailableView("No Shipments", systemImage: "shippingbox")
        } else {
            List(viewModel.shipments) { shipment in
                NavigationLink {
                    ShipmentDetailView(apiClient: apiClient, shipment: shipment)
                } label: {
                    ShipmentRow(shipment: shipment)
                }
                .task {
                    await viewModel.loadMoreIfNeeded(currentItem: shipment)
                }
            }
            .listStyle(.plain)
        }
    }
}

private struct ShipmentRow: View {
    let shipment: Shipment

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(shipment.easyshipShipmentId)
                .font(.headline)
            if let courier = shipment.courierService?.name {
                Text(courier)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                if let state = shipment.shipmentState {
                    StatusBadge(text: state)
                }
                if let deliveryState = shipment.deliveryState {
                    StatusBadge(text: deliveryState)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct StatusBadge: View {
    let text: String

    var body: some View {
        Text(text.capitalized)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.secondary.opacity(0.15), in: Capsule())
    }
}

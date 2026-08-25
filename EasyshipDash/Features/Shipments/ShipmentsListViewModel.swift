import Foundation

@Observable
final class ShipmentsListViewModel {
    private let apiClient: EasyshipAPIClient
    private let perPage = 20

    var shipments: [Shipment] = []
    var isLoading = false
    var errorMessage: String?
    var selectedState: String? {
        didSet { if oldValue != selectedState { Task { await reload() } } }
    }

    private var currentPage = 1
    private var hasMorePages = true

    static let states = ["created", "cancelled"]

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
    }

    @MainActor
    func reload() async {
        currentPage = 1
        hasMorePages = true
        shipments = []
        await loadNextPage()
    }

    @MainActor
    func loadNextPage() async {
        guard !isLoading, hasMorePages else { return }
        isLoading = true
        errorMessage = nil

        var query: [String: String] = ["page": "\(currentPage)", "per_page": "\(perPage)"]
        if let selectedState { query["shipment_state"] = selectedState }

        do {
            let response: ShipmentsResponse = try await apiClient.get("/shipments", query: query)
            shipments.append(contentsOf: response.shipments)
            if let next = response.meta?.pagination?.next {
                currentPage = next
                hasMorePages = true
            } else {
                hasMorePages = false
            }
        } catch {
            errorMessage = (error as? EasyshipAPIError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }

    @MainActor
    func loadMoreIfNeeded(currentItem: Shipment) async {
        guard let index = shipments.firstIndex(where: { $0.id == currentItem.id }) else { return }
        if index >= shipments.count - 5 {
            await loadNextPage()
        }
    }
}

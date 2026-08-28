import Foundation

@Observable
final class ShipmentsListViewModel {
    private let apiClient: EasyshipAPIClient
    private let perPage = 20

    var shipments: [Shipment] = []
    var isLoading = false
    var errorMessage: String?
    /// Set through `select(state:)` rather than a `didSet` that kicks off a detached reload — the
    /// caller needs to be able to await the refresh, and the fire-and-forget version raced with the
    /// load already in flight.
    private(set) var selectedState: String?

    private var currentPage = 1
    private var hasMorePages = true

    /// Bumped by every `reload()`. An in-flight page that comes back with a stale generation belongs
    /// to a superseded filter, so it drops its results instead of appending them to the new list.
    private var generation = 0

    static let states = ["created", "cancelled"]

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
    }

    @MainActor
    func select(state: String?) async {
        guard state != selectedState else { return }
        selectedState = state
        await reload()
    }

    @MainActor
    func reload() async {
        generation &+= 1
        currentPage = 1
        hasMorePages = true
        shipments = []
        errorMessage = nil
        isLoading = false
        await loadNextPage()
    }

    @MainActor
    func loadNextPage() async {
        guard !isLoading, hasMorePages else { return }
        let requestGeneration = generation
        isLoading = true
        errorMessage = nil

        var query: [String: String] = ["page": "\(currentPage)", "per_page": "\(perPage)"]
        if let selectedState { query["shipment_state"] = selectedState }

        do {
            let response: ShipmentsResponse = try await apiClient.get("/shipments", query: query)
            guard requestGeneration == generation else { return }
            shipments.append(contentsOf: response.shipments)
            if let next = response.meta?.pagination?.next {
                currentPage = next
                hasMorePages = true
            } else {
                hasMorePages = false
            }
        } catch {
            guard requestGeneration == generation else { return }
            errorMessage = (error as? EasyshipAPIError)?.errorDescription ?? error.localizedDescription
            hasMorePages = false
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

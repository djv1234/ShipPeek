import CoreLocation
import Foundation

@Observable
final class RateCalculatorViewModel {
    private let apiClient: EasyshipAPIClient
    private let geocoder = CLGeocoder()

    var destination: Address = .empty
    var isLookingUpZip = false
    var weightLb: String = ""
    var lengthIn: String = ""
    var widthIn: String = ""
    var heightIn: String = ""
    var itemValue: String = ""

    var quotes: [RateQuote] = []
    var isLoading = false
    var errorMessage: String?

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
    }

    var canSubmit: Bool {
        destination.isValidForRateRequest && Double(weightLb) != nil && !isLoading
    }

    /// Best-effort city/state fill-in from country + postal code, so the destination form only
    /// needs those two fields — matches what Easyship's own quote tool asks for. Not required for
    /// submission: if the lookup fails or the country's postal system isn't geocodable, the
    /// request still goes out with just country + postal code.
    @MainActor
    func lookupCityStateIfNeeded() async {
        let postalCode = destination.postalCode.trimmingCharacters(in: .whitespaces)
        guard postalCode.count >= 3, !destination.countryAlpha2.isEmpty else { return }
        guard let countryName = Locale.current.localizedString(forRegionCode: destination.countryAlpha2) else { return }

        isLookingUpZip = true

        if let placemark = try? await geocoder.geocodeAddressString("\(postalCode), \(countryName)").first {
            destination.city = placemark.locality ?? destination.city
            destination.state = placemark.administrativeArea ?? destination.state
        }

        isLookingUpZip = false
    }

    @MainActor
    func fetchRates() async {
        guard let weight = Double(weightLb) else {
            errorMessage = "Enter a valid parcel weight in lb."
            return
        }

        isLoading = true
        errorMessage = nil
        quotes = []

        var dimensions: ParcelBox?
        if let length = Double(lengthIn), let width = Double(widthIn), let height = Double(heightIn) {
            dimensions = ParcelBox(length: length, width: width, height: height)
        }

        let item = ParcelItem(
            description: "Item",
            originCountryAlpha2: DefaultShipFromStore.load().countryAlpha2,
            quantity: 1,
            dimensions: dimensions,
            actualWeight: weight,
            declaredCurrency: "USD",
            declaredCustomsValue: Double(itemValue) ?? 0
        )
        let parcel = Parcel(totalActualWeight: weight, box: nil, items: [item])
        let request = RatesRequest(
            originAddress: DefaultShipFromStore.load(),
            destinationAddress: destination,
            parcels: [parcel],
            shippingSettings: ShippingSettings(units: Units(weight: "lb", dimensions: "in"))
        )

        do {
            let response: RatesResponse = try await apiClient.post("/rates", body: request)
            quotes = response.rates.sorted { ($0.totalCharge ?? .greatestFiniteMagnitude) < ($1.totalCharge ?? .greatestFiniteMagnitude) }
        } catch {
            errorMessage = (error as? EasyshipAPIError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}

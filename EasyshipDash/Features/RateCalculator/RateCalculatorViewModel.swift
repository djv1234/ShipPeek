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

    /// Mirrored from `DefaultShipFromStore` so the view can react to it. Refreshed whenever the tab
    /// appears, since Settings may have changed it since this view model was created.
    private(set) var shipFrom: Address

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
        self.shipFrom = DefaultShipFromStore.load()
    }

    func refreshShipFrom() {
        shipFrom = DefaultShipFromStore.load()
    }

    var hasShipFromAddress: Bool {
        shipFrom.isValidForRateRequest
    }

    var canSubmit: Bool {
        hasShipFromAddress && destination.isValidForRateRequest && parsedWeight != nil && !isLoading
    }

    /// `Double("inf")` and `Double("nan")` both parse, and `JSONEncoder` refuses to encode either —
    /// which would surface as an opaque "couldn't build the request" rather than a bad-input message.
    private var parsedWeight: Double? {
        guard let weight = Double(weightLb), weight.isFinite, weight > 0 else { return nil }
        return weight
    }

    private var parsedItemValue: Double {
        guard let value = Double(itemValue), value.isFinite, value >= 0 else { return 0 }
        return value
    }

    private func positiveDimension(_ text: String) -> Double? {
        guard let value = Double(text), value.isFinite, value > 0 else { return nil }
        return value
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
        refreshShipFrom()

        guard hasShipFromAddress else {
            errorMessage = "Set your ship-from address in Settings first — it's the origin for every rate request."
            return
        }
        guard let weight = parsedWeight else {
            errorMessage = "Enter a valid parcel weight in lb."
            return
        }

        isLoading = true
        errorMessage = nil
        quotes = []

        var dimensions: ParcelBox?
        if let length = positiveDimension(lengthIn),
           let width = positiveDimension(widthIn),
           let height = positiveDimension(heightIn) {
            dimensions = ParcelBox(length: length, width: width, height: height)
        }

        let item = ParcelItem(
            description: "Item",
            originCountryAlpha2: shipFrom.countryAlpha2,
            quantity: 1,
            dimensions: dimensions,
            actualWeight: weight,
            declaredCurrency: "USD",
            declaredCustomsValue: parsedItemValue
        )
        let parcel = Parcel(totalActualWeight: weight, box: nil, items: [item])
        let request = RatesRequest(
            originAddress: shipFrom,
            destinationAddress: destination,
            parcels: [parcel],
            shippingSettings: ShippingSettings(units: Units(weight: "lb", dimensions: "in"))
        )

        do {
            let response: RatesResponse = try await apiClient.post("/rates", body: request)
            quotes = response.rates.sorted { ($0.totalCharge ?? .greatestFiniteMagnitude) < ($1.totalCharge ?? .greatestFiniteMagnitude) }
            if quotes.isEmpty {
                errorMessage = "Easyship returned no rates for this route. Try a different destination or weight."
            }
        } catch {
            errorMessage = (error as? EasyshipAPIError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}

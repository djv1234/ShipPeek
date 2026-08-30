import CoreLocation
import Foundation

@Observable
final class RateCalculatorViewModel {
    private let apiClient: EasyshipAPIClient
    private let shipFromStore: ShipFromStore
    private let walkthrough: WalkthroughState
    private let geocoder = CLGeocoder()

    var destination: Address = .empty
    var isLookingUpZip = false
    var weightLb: String = ""
    var lengthIn: String = ""
    var widthIn: String = ""
    var heightIn: String = ""
    var itemValue: String = ""
    /// Easyship's customs check wants an `item_category_id` or an `hs_code` — the plain `category`
    /// string gets past the first validation pass but not the second, so one of these two is
    /// genuinely required. The HS code is the one a user can actually look up.
    var hsCode: String = ""
    var itemCategoryId: String = ""

    var quotes: [RateQuote] = []
    var isLoading = false
    var errorMessage: String?

    init(
        apiClient: EasyshipAPIClient,
        shipFromStore: ShipFromStore = .shared,
        walkthrough: WalkthroughState = .shared
    ) {
        self.apiClient = apiClient
        self.shipFromStore = shipFromStore
        self.walkthrough = walkthrough
    }

    /// Read through to the shared store on every access, so saving an address in Settings takes
    /// effect here without the two screens having to coordinate.
    var shipFrom: Address {
        shipFromStore.address
    }

    var hasShipFromAddress: Bool {
        shipFrom.isValidForRateRequest
    }

    var canSubmit: Bool {
        missingRequirements.isEmpty && !isLoading
    }

    /// Everything still standing between the form and a request. Surfaced in the UI, because a
    /// disabled button with no explanation is impossible to debug from the outside — and because
    /// every entry here was learned from a live 422 rather than from the docs.
    var missingRequirements: [String] {
        var missing: [String] = []
        if !hasShipFromAddress {
            missing.append("A ship-from address in Settings (country, plus ZIP for US origins)")
        }
        if destination.countryAlpha2.isEmpty {
            missing.append("A destination country")
        } else if destination.countryAlpha2 == "US" && destination.postalCode.isEmpty {
            missing.append("A destination ZIP code")
        }
        if parsedWeight == nil {
            missing.append("A parcel weight in lb")
        }
        if parsedDimensions == nil {
            missing.append("Parcel dimensions — length, width and height in inches")
        }
        if trimmedHSCode == nil && trimmedItemCategoryId == nil {
            missing.append("An HS code (or an Easyship item category ID)")
        }
        return missing
    }

    private var trimmedHSCode: String? {
        let trimmed = hsCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private var trimmedItemCategoryId: String? {
        let trimmed = itemCategoryId.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Required, despite reading as optional: Easyship rejects a rate request whose item carries no
    /// dimensions. All three have to be present for the box to mean anything.
    private var parsedDimensions: ParcelBox? {
        guard let length = positiveDimension(lengthIn),
              let width = positiveDimension(widthIn),
              let height = positiveDimension(heightIn)
        else { return nil }
        return ParcelBox(length: length, width: width, height: height)
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
        guard let weight = parsedWeight, let dimensions = parsedDimensions, missingRequirements.isEmpty else {
            errorMessage = "Still needed: " + missingRequirements.joined(separator: ", ")
            return
        }

        isLoading = true
        errorMessage = nil
        quotes = []

        let item = ParcelItem(
            description: "Item",
            // Sent alongside the id/HS code because it satisfies Easyship's first validation pass;
            // harmless when an HS code is present, and the two passes complain separately.
            category: ParcelItem.defaultCategory,
            itemCategoryId: trimmedItemCategoryId,
            hsCode: trimmedHSCode,
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
            walkthrough.markRatesFetched()
            if quotes.isEmpty {
                errorMessage = "Easyship returned no rates for this route. Try a different destination or weight."
            }
        } catch {
            errorMessage = (error as? EasyshipAPIError)?.errorDescription ?? error.localizedDescription
        }

        isLoading = false
    }
}

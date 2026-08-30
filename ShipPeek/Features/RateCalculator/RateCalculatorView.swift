import SwiftUI

struct RateCalculatorView: View {
    /// One case per editable field so the keyboard toolbar can move between them. The number pads
    /// have no return key of their own, so without this there is no way to dismiss the keyboard
    /// except tapping a non-scrolling part of the form.
    private enum Field: Hashable {
        case postalCode, weight, length, width, height, value, hsCode, itemCategoryId
    }

    @State private var viewModel: RateCalculatorViewModel
    @State private var showFullAddress = false
    @FocusState private var focusedField: Field?

    private let walkthrough = WalkthroughState.shared

    init(apiClient: EasyshipAPIClient) {
        _viewModel = State(initialValue: RateCalculatorViewModel(apiClient: apiClient))
    }

    private var isShowingCoachBubble: Bool {
        !walkthrough.hasFetchedRates && walkthrough.shouldShow(WalkthroughState.Tip.rateCalculator)
    }

    var body: some View {
        NavigationStack {
            Form {
                if isShowingCoachBubble {
                    CoachBubble(
                        text: "Fill in where it's going, then the parcel's weight and size. Easyship needs all of those plus an HS code to classify the goods — anything still missing is listed under the Get Rates button."
                    ) {
                        walkthrough.dismiss(WalkthroughState.Tip.rateCalculator)
                    }
                }

                Section("Destination") {
                    CountryPickerField(countryAlpha2: $viewModel.destination.countryAlpha2)

                    TextField(
                        viewModel.destination.countryAlpha2 == "US" ? "ZIP code" : "Postal code (optional)",
                        text: $viewModel.destination.postalCode
                    )
                        .focused($focusedField, equals: .postalCode)
                        .onChange(of: viewModel.destination.postalCode) {
                            Task { await viewModel.lookupCityStateIfNeeded() }
                        }
                        .onChange(of: viewModel.destination.countryAlpha2) {
                            Task { await viewModel.lookupCityStateIfNeeded() }
                        }
                    if viewModel.isLookingUpZip {
                        ProgressView()
                    } else if !viewModel.destination.city.isEmpty {
                        Text("\(viewModel.destination.city), \(viewModel.destination.state)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if showFullAddress {
                        TextField("Contact name", text: $viewModel.destination.contactName)
                        TextField("Company (optional)", text: $viewModel.destination.companyName)
                        TextField("Address line 1", text: $viewModel.destination.line1)
                        TextField("Address line 2 (optional)", text: $viewModel.destination.line2)
                        TextField("City", text: $viewModel.destination.city)
                        TextField("State / Province", text: $viewModel.destination.state)
                    } else {
                        Button("Add full address details") {
                            withAnimation { showFullAddress = true }
                        }
                    }
                }

                Section {
                    TextField("Total weight (lb)", text: $viewModel.weightLb)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .weight)

                    TextField("Length (in)", text: $viewModel.lengthIn)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .length)
                    TextField("Width (in)", text: $viewModel.widthIn)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .width)
                    TextField("Height (in)", text: $viewModel.heightIn)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .height)

                    TextField("Value, $", text: $viewModel.itemValue)
                        .keyboardType(.decimalPad)
                        .focused($focusedField, equals: .value)
                } header: {
                    Text("Parcel")
                } footer: {
                    Text("Weight and all three dimensions are required — Easyship rejects a quote request without them. Couriers bill by whichever is greater, actual or dimensional weight, so the size matters to the price.")
                }

                Section {
                    TextField("HS code — 8 digits, e.g. 42029100", text: $viewModel.hsCode)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .hsCode)
                    TextField("Easyship item category ID (alternative)", text: $viewModel.itemCategoryId)
                        .keyboardType(.numbersAndPunctuation)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .itemCategoryId)
                } header: {
                    Text("Customs")
                } footer: {
                    Text("Easyship needs one of these to classify the goods. The HS code is the easier one to find — Easyship publishes a free lookup tool at easyship.com/hs-tariff-code-lookup. Codes are eight digits ending in 00.")
                }

                Section {
                    Button {
                        focusedField = nil
                        Task { await viewModel.fetchRates() }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text("Get Rates")
                        }
                    }
                    .disabled(!viewModel.canSubmit)
                } footer: {
                    if !viewModel.missingRequirements.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Still needed:")
                            ForEach(viewModel.missingRequirements, id: \.self) { requirement in
                                Text("• \(requirement)")
                            }
                        }
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }

                if !viewModel.quotes.isEmpty {
                    Section("Quotes") {
                        ForEach(viewModel.quotes) { quote in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(quote.courierService.name)
                                    .font(.headline)
                                Text(CurrencyFormatting.format(quote.totalCharge, currencyCode: quote.currency ?? "USD"))
                                    .font(.subheadline)
                                if let min = quote.minDeliveryTime, let max = quote.maxDeliveryTime {
                                    Text("\(min)-\(max) business days")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Rate Calculator")
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }
                }
            }
        }
    }
}

import SwiftUI

struct RateCalculatorView: View {
    @State private var viewModel: RateCalculatorViewModel
    @State private var showFullAddress = false
    @State private var showDimensions = false

    init(apiClient: EasyshipAPIClient) {
        _viewModel = State(initialValue: RateCalculatorViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Destination") {
                    CountryPickerField(countryAlpha2: $viewModel.destination.countryAlpha2)

                    TextField(
                        viewModel.destination.countryAlpha2 == "US" ? "ZIP code" : "Postal code (optional)",
                        text: $viewModel.destination.postalCode
                    )
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

                Section("Parcel") {
                    TextField("Total weight (lb)", text: $viewModel.weightLb)
                        .keyboardType(.decimalPad)

                    if showDimensions {
                        TextField("Length (in)", text: $viewModel.lengthIn)
                            .keyboardType(.decimalPad)
                        TextField("Width (in)", text: $viewModel.widthIn)
                            .keyboardType(.decimalPad)
                        TextField("Height (in)", text: $viewModel.heightIn)
                            .keyboardType(.decimalPad)
                    } else {
                        Button("Add dimensions") {
                            withAnimation { showDimensions = true }
                        }
                        Text("Optional, but couriers bill by whichever is greater: actual or dimensional (volumetric) weight — worth adding for bulky-but-light items.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    TextField("Value, $", text: $viewModel.itemValue)
                        .keyboardType(.decimalPad)
                }

                Section {
                    Button {
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
        }
    }
}

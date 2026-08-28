import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(apiClient: EasyshipAPIClient) {
        _viewModel = State(initialValue: SettingsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("API Access") {
                    Picker("Environment", selection: $viewModel.selectedEnvironment) {
                        ForEach(EasyshipEnvironment.allCases) { env in
                            Text(env.displayName).tag(env)
                        }
                    }
                    SecureField("API token", text: $viewModel.tokenInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save Token") {
                        viewModel.saveToken()
                    }
                    .disabled(!viewModel.canSave)
                }

                Section {
                    AddressFormSection(address: $viewModel.shipFromAddress)
                    Button("Save Address") {
                        viewModel.saveShipFromAddress()
                    }
                } header: {
                    Text("Default Ship-From Address")
                } footer: {
                    if !viewModel.isShipFromComplete {
                        Text("Country is required (plus a ZIP code for US origins) before the Rate Calculator can request quotes.")
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        viewModel.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .onChange(of: viewModel.selectedEnvironment) {
                viewModel.reloadTokenForSelectedEnvironment()
            }
            .alert("Saved", isPresented: $viewModel.savedConfirmation) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

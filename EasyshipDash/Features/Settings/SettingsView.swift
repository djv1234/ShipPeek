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

                Section("Default Ship-From Address") {
                    AddressFormSection(address: $viewModel.shipFromAddress)
                    Button("Save Address") {
                        viewModel.saveShipFromAddress()
                    }
                }

                Section {
                    Button("Sign Out", role: .destructive) {
                        viewModel.signOut()
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Saved", isPresented: $viewModel.savedConfirmation) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

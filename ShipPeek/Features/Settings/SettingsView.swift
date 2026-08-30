import SwiftUI

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel
    private let walkthrough = WalkthroughState.shared

    init(apiClient: EasyshipAPIClient) {
        _viewModel = State(initialValue: SettingsViewModel(apiClient: apiClient))
    }

    var body: some View {
        NavigationStack {
            Form {
                if !viewModel.isShipFromComplete, walkthrough.shouldShow(WalkthroughState.Tip.shipFrom) {
                    CoachBubble(
                        text: "Set your ship-from address once and every rate quote will use it as the origin. Tap the Country row below — it's the only field that's strictly required."
                    ) {
                        walkthrough.dismiss(WalkthroughState.Tip.shipFrom)
                    }
                }

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
                    Button("Show Walkthrough Again") {
                        walkthrough.replay()
                    }
                } footer: {
                    Text("Replays the welcome screen and the inline tips — handy when handing this build to a new tester.")
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

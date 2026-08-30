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
                // Shown until dismissed, not only while the address is incomplete: gating it on
                // completeness meant anyone who had already filled the address in never saw the
                // walkthrough's Settings step at all, including after replaying it.
                if walkthrough.shouldShow(WalkthroughState.Tip.shipFrom) {
                    CoachBubble(
                        text: "Start here: paste your API token, then set the ship-from address below. Every rate quote uses it as the origin, so it's a one-time step — tap the Country row, it's the only field that's strictly required."
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

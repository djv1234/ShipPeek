import SwiftUI

@main
struct EasyshipDashApp: App {
    @State private var apiClient = EasyshipAPIClient()

    var body: some Scene {
        WindowGroup {
            RootView(apiClient: apiClient)
        }
    }
}

private struct RootView: View {
    let apiClient: EasyshipAPIClient
    @State private var hasToken: Bool

    init(apiClient: EasyshipAPIClient) {
        self.apiClient = apiClient
        _hasToken = State(initialValue: apiClient.hasToken)
    }

    var body: some View {
        Group {
            if hasToken {
                MainTabView(apiClient: apiClient)
            } else {
                OnboardingView(apiClient: apiClient, hasToken: $hasToken)
            }
        }
    }
}

private struct MainTabView: View {
    let apiClient: EasyshipAPIClient

    var body: some View {
        TabView {
            RateCalculatorView(apiClient: apiClient)
                .tabItem { Label("Rates", systemImage: "dollarsign.circle") }

            ShipmentsListView(apiClient: apiClient)
                .tabItem { Label("Shipments", systemImage: "shippingbox") }

            SettingsView(apiClient: apiClient)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}

private struct OnboardingView: View {
    let apiClient: EasyshipAPIClient
    @Binding var hasToken: Bool

    @State private var environment: EasyshipEnvironment = .sandbox
    @State private var token: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Add your Easyship API token to get started.")
                        .foregroundStyle(.secondary)
                }
                Section("API Access") {
                    Picker("Environment", selection: $environment) {
                        ForEach(EasyshipEnvironment.allCases) { env in
                            Text(env.displayName).tag(env)
                        }
                    }
                    SecureField("API token", text: $token)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                Section {
                    Button("Continue") {
                        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        KeychainStore.setToken(trimmed, for: environment)
                        apiClient.environment = environment
                        hasToken = true
                    }
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

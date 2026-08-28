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

    var body: some View {
        // Reads the client's observable `hasToken` directly, so signing out in Settings drops
        // straight back to onboarding instead of leaving an unusable tab view on screen.
        if apiClient.hasToken {
            MainTabView(apiClient: apiClient)
        } else {
            OnboardingView(apiClient: apiClient)
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
                        apiClient.setToken(trimmed, for: environment)
                    }
                    .disabled(token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Welcome")
        }
    }
}

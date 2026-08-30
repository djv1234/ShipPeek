import SwiftUI

@main
struct ShipPeekApp: App {
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

    private let walkthrough = WalkthroughState.shared

    /// Derived from the store rather than copied into local state on appear. "Show Walkthrough
    /// Again" flips `hasSeenWelcome` back to false, and a one-shot `onAppear` had already run by
    /// then — so the button appeared to do nothing at all.
    private var isShowingWelcome: Binding<Bool> {
        Binding(
            get: { !walkthrough.hasSeenWelcome },
            set: { isPresented in
                if !isPresented { walkthrough.markWelcomeSeen() }
            }
        )
    }

    var body: some View {
        TabView {
            RateCalculatorView(apiClient: apiClient)
                .tabItem { Label("Rates", systemImage: "dollarsign.circle") }

            ShipmentsListView(apiClient: apiClient)
                .tabItem { Label("Shipments", systemImage: "shippingbox") }

            SettingsView(apiClient: apiClient)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        // The binding's setter marks it seen, so swiping the sheet away counts the same as tapping
        // Get Started — nobody wants the same intro every launch.
        .sheet(isPresented: isShowingWelcome) {
            WelcomeSheet { walkthrough.markWelcomeSeen() }
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

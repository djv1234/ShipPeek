import SwiftUI

/// Shown once, immediately after the token is accepted. Answers "cool, what now?" before the user
/// has to ask it: three tabs, two setup steps, in the order they need to happen.
struct WelcomeSheet: View {
    let onFinish: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to ShipPeek")
                            .font(.largeTitle.bold())
                        Text("Compare courier rates and track what you've already shipped.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 20) {
                        WelcomeStep(
                            number: 1,
                            systemImage: "shippingbox.fill",
                            title: "Set your ship-from address",
                            detail: "In the Settings tab. Every quote uses it as the origin, so this is a one-time step — Country is required."
                        )
                        WelcomeStep(
                            number: 2,
                            systemImage: "dollarsign.circle.fill",
                            title: "Get a rate",
                            detail: "In the Rates tab, pick a destination country and enter a parcel weight. Dimensions and value are optional."
                        )
                        WelcomeStep(
                            number: 3,
                            systemImage: "location.fill",
                            title: "Track shipments",
                            detail: "The Shipments tab lists everything on your Easyship account, with checkpoint-level tracking on each one."
                        )
                    }

                    Text("You're in the Sandbox environment unless you switch it in Settings — quotes there are test data, not bookable rates.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    onFinish()
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 16)
                .background(.bar)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct WelcomeStep: View {
    let number: Int
    let systemImage: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(.tint)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(number). \(title)")
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

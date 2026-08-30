import SwiftUI

/// A dismissible inline hint — the "thought bubble" of the first-run walkthrough.
///
/// Deliberately inline in the form flow rather than a floating overlay: a callout anchored beside
/// the control it describes can't drift out of place on a small screen or in landscape, and it
/// doesn't block the field the user is being told to fill in.
struct CoachBubble: View {
    let text: String
    var systemImage: String = "lightbulb.fill"
    var onDismiss: (() -> Void)?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            Text(text)
                .font(.footnote)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let onDismiss {
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss tip")
            }
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
    }
}

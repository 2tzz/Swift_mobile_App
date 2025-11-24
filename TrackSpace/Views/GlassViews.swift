import SwiftUI

// Reusable glass-like card container
struct GlassCard<Content: View>: View {
    var content: () -> Content
    var cornerRadius: CGFloat = 16
    var body: some View {
        ZStack {
            // subtle blurred background
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.cardStroke, lineWidth: 1)
                )
                .shadow(color: Theme.shadow.opacity(0.35), radius: 18, x: 0, y: 12)

            content()
                .padding()
        }
    }
}

// Reusable primary button matching the glass theme
struct PrimaryButton<Label: View>: View {
    var action: () -> Void
    var label: () -> Label
    var body: some View {
        Button(action: action) {
            label()
                .font(.headline)
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(Theme.headerGradient)
                .clipShape(Capsule())
                .shadow(color: Theme.primaryStart.opacity(0.32), radius: 14, x: 0, y: 10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

import SwiftUI

struct AppCardContainerStyle: ViewModifier {
    var cornerRadius: CGFloat = 14
    var shadowRadius: CGFloat = 8
    func body(content: Content) -> some View {
        content
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Theme.cardStroke, lineWidth: 1)
                    )
                    .shadow(color: Theme.shadow.opacity(0.35), radius: shadowRadius, x: 0, y: 6)
            )
    }
}

extension View {
    func appCardStyle(cornerRadius: CGFloat = 14, shadowRadius: CGFloat = 8) -> some View {
        modifier(AppCardContainerStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }

    func appPrimaryGradientBackground() -> some View {
        background(Theme.backgroundGradient)
    }

    func appPrimaryButtonStyle() -> some View {
        self
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.headerGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: Theme.primaryStart.opacity(0.35), radius: 14, x: 0, y: 8)
    }
}

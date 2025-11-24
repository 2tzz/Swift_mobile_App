import SwiftUI

struct AppCardContainerStyle: ViewModifier {
    var cornerRadius: CGFloat = 14
    var shadowRadius: CGFloat = 8
    func body(content: Content) -> some View {
        content
            .background(Theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Theme.shadow, radius: shadowRadius, x: 0, y: 4)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Theme.border)
            )
    }
}

extension View {
    func appCardStyle(cornerRadius: CGFloat = 14, shadowRadius: CGFloat = 8) -> some View {
        modifier(AppCardContainerStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }

    func appPrimaryGradientBackground() -> some View {
        background(Theme.headerGradient)
    }

    func appPrimaryButtonStyle() -> some View {
        self
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(Theme.headerGradient)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

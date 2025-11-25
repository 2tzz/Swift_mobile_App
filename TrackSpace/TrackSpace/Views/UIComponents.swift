import SwiftUI

// Reusable card style modifier for consistent elevated card appearance
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 6
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.15), radius: shadowRadius, x: 0, y: 4)
    }
}

extension View {
    func cardStyle(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 6) -> some View {
        self.modifier(CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius))
    }
}

// Small animated badge used for counts or status
struct AnimatedBadge: View {
    let text: String
    var color: Color = .accentColor
    @State private var scale: CGFloat = 0.6
    var body: some View {
        Text(text)
            .font(.caption.bold())
            .padding(6)
            .background(color)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(scale)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                    scale = 1
                }
            }
    }
}

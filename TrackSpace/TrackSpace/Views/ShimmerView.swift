import SwiftUI

struct Shimmer: View {
    @State private var offset: CGFloat = -1.0
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.04), Color.white.opacity(0.18), Color.white.opacity(0.04)]), startPoint: .leading, endPoint: .trailing)
                .frame(width: w * 1.6, height: geo.size.height)
                .rotationEffect(.degrees(20))
                .offset(x: offset * w * 1.6)
                .onAppear {
                    withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                        offset = 1.0
                    }
                }
        }
        .clipped()
    }
}

import SwiftUI

/// Animated "liquid glass" style background using softly blurred gradient blobs.
/// Works on iOS 16+ (TimelineView + .ultraThinMaterial supported).
struct LiquidBackground: View {
    var body: some View {
        TimelineView(.animation) { context in
            let t = context.date.timeIntervalSinceReferenceDate
            ZStack {
                // Base gradient wash
                LinearGradient(
                    colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.35)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Animated blobs
                Blob(color1: .cyan, color2: .blue, time: t, speed: 0.3, size: 420, x: 0.35, y: 0.25)
                    .blur(radius: 60)
                Blob(color1: .purple, color2: .pink, time: t, speed: 0.22, size: 460, x: 0.7, y: 0.75)
                    .blur(radius: 70)
                Blob(color1: .indigo, color2: .mint, time: t, speed: 0.27, size: 380, x: 0.15, y: 0.75)
                    .blur(radius: 50)
            }
        }
    }
}

private struct Blob: View {
    let color1: Color
    let color2: Color
    let time: TimeInterval
    let speed: Double
    let size: CGFloat
    let x: CGFloat
    let y: CGFloat

    var body: some View {
        // Parametric motion
        let dx = cos(time * speed) * 80
        let dy = sin(time * speed * 1.1) * 80
        let rotation = Angle(degrees: sin(time * speed) * 40)

        Circle()
            .fill(
                RadialGradient(colors: [color1, color2], center: .center, startRadius: 10, endRadius: size/2)
            )
            .frame(width: size, height: size)
            .position(x: UIScreen.main.bounds.width * x + dx,
                      y: UIScreen.main.bounds.height * y + dy)
            .rotationEffect(rotation)
            .opacity(0.9)
    }
}

#Preview {
    LiquidBackground()
}

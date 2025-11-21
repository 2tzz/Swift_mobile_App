import SwiftUI

struct LoadingView: View {
    var onFinished: () -> Void

    @State private var isPulsing: Bool = false
    @State private var scanOffset: CGFloat = -60

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.gray.opacity(0.95), Color.black.opacity(0.98)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.yellow.opacity(0.5), lineWidth: 2)
                        .frame(width: 220, height: 140)
                        .overlay {
                            ZStack {
                                ForEach(0..<3) { index in
                                    Capsule()
                                        .fill(Color.white.opacity(0.10))
                                        .frame(height: 4)
                                        .offset(y: CGFloat(index * 16 - 16))
                                }

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.yellow.opacity(0),
                                                Color.yellow,
                                                Color.yellow.opacity(0)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: 200, height: 80)
                                    .offset(x: scanOffset)
                                    .blur(radius: 4)
                            }
                        }
                        .shadow(color: Color.yellow.opacity(0.2), radius: 16, x: 0, y: 8)

                    VStack {
                        Image(systemName: "road.lanes")
                            .font(.system(size: 56, weight: .semibold))
                            .foregroundStyle(Color.yellow)
                            .scaleEffect(isPulsing ? 1.08 : 0.94)
                            .shadow(color: Color.yellow.opacity(0.6), radius: 18, x: 0, y: 0)

                        Circle()
                            .fill(Color.yellow.opacity(0.18))
                            .frame(width: 70, height: 10)
                            .blur(radius: 8)
                            .scaleEffect(isPulsing ? 1.15 : 0.85)
                    }
                    .offset(y: 10)
                }

                VStack(spacing: 8) {
                    Text("FixLK")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Assessing urban road safety and reporting issues")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(Color.yellow.opacity(0.85))
                }

                ProgressView()
                    .tint(Color.yellow)
                    .progressViewStyle(.circular)
            }
            .padding(32)
        }
        .task {
            startAnimations()
            await performStartupDelay()
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            isPulsing = true
        }

        withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
            scanOffset = 60
        }
    }

    private func performStartupDelay() async {
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        await MainActor.run {
            onFinished()
        }
    }
}

#Preview {
    LoadingView {} 
}

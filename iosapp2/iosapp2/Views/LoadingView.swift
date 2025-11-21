import SwiftUI

struct LoadingView: View {
    var onFinished: () -> Void

    @State private var isPulsing: Bool = false
    @State private var scanOffset: CGFloat = -60

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.9), Color.black.opacity(0.9)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 220, height: 140)
                        .overlay {
                            ZStack {
                                ForEach(0..<3) { index in
                                    Capsule()
                                        .fill(Color.white.opacity(0.15))
                                        .frame(height: 4)
                                        .offset(y: CGFloat(index * 16 - 16))
                                }

                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0),
                                                Color.white.opacity(0.7),
                                                Color.white.opacity(0)
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
                        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: 8)

                    VStack {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(.white)
                            .scaleEffect(isPulsing ? 1.08 : 0.94)
                            .shadow(color: Color.blue.opacity(0.6), radius: 18, x: 0, y: 0)

                        Circle()
                            .fill(Color.white.opacity(0.18))
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

                    Text("Scanning nearby roads for issues")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                }

                ProgressView()
                    .tint(.white)
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

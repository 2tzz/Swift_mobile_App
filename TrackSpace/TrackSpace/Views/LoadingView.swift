import SwiftUI

struct LoadingView: View {
    var message: String = "Loading..."
    @State private var pulse = false
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Theme.primaryStart.opacity(0.9), Theme.primaryEnd.opacity(0.9)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse ? 1.12 : 0.9)
                    Circle()
                        .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(pulse ? 360 : 0))
                        .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: false), value: pulse)
                    Image(systemName: "shippingbox.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundColor(.white)
                        .shadow(radius: 6)
                }

                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            }
            .padding(28)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(Shimmer().clipShape(RoundedRectangle(cornerRadius: 18)).opacity(0.6))
            .padding(.horizontal, 20)
            .onAppear { pulse = true }
            .shadow(color: Color.black.opacity(0.2), radius: 18, x: 0, y: 12)
        }
    }
}

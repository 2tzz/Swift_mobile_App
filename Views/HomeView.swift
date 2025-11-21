import SwiftUI

struct HomeView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                Text("CivicFix")
                    .font(.largeTitle.bold())

                Text("Home / Map dashboard will appear here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
}

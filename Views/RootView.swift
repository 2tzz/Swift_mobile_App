import SwiftUI

struct RootView: View {
    @State private var isLoading: Bool = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingView {
                        isLoading = false
                    }
                } else {
                    HomeView()
                }
            }
        }
    }
}

#Preview {
    RootView()
}

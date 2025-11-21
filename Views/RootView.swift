import SwiftUI

struct RootView: View {
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView {
                    isLoading = false
                }
            } else {
                TabView {
                    NavigationStack {
                        HomeView()
                    }
                    .tabItem {
                        Label("Home", systemImage: "map")
                    }

                    NavigationStack {
                        ProfileView()
                    }
                    .tabItem {
                        Label("Profile", systemImage: "person.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    RootView()
}

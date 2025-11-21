import SwiftUI

struct RootView: View {
    @State private var isLoading: Bool = true
    @EnvironmentObject private var auth: AuthService

    var body: some View {
        Group {
            if isLoading {
                LoadingView {
                    isLoading = false
                }
            } else {
                if auth.currentUser == nil {
                    NavigationStack { LoginView() }
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
}

#Preview {
    RootView()
}

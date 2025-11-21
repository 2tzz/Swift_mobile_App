import SwiftUI
#if canImport(FirebaseCore)
import FirebaseCore
#endif

@main
struct FixLKApp: App {
    @StateObject private var auth = AuthService()
    init() {
        #if canImport(FirebaseCore)
        FirebaseApp.configure()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(auth)
        }
    }
}

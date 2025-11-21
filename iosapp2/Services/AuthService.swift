import Foundation
import Combine
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

final class AuthService: ObservableObject {
    @Published private(set) var currentUser: User? = nil
    @Published private(set) var isAuthenticating: Bool = false
    @Published var authError: String? = nil

    #if canImport(FirebaseAuth)
    private var authHandle: AuthStateDidChangeListenerHandle?
    #endif

    init() {
        #if canImport(FirebaseAuth)
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let u = user {
                    let name = u.displayName ?? (u.email?.components(separatedBy: "@").first ?? "User")
                    self.currentUser = User(id: u.uid, name: name, email: u.email ?? "")
                } else {
                    self.currentUser = nil
                }
            }
        }
        #endif
    }

    deinit {
        #if canImport(FirebaseAuth)
        if let h = authHandle { Auth.auth().removeStateDidChangeListener(h) }
        #endif
    }

    @MainActor
    func signIn(email: String, password: String) async {
        guard !email.isEmpty, !password.isEmpty else {
            self.authError = "Please enter email and password."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        #if canImport(FirebaseAuth)
        do {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                Auth.auth().signIn(withEmail: email, password: password) { _, error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            self.authError = nil
        } catch {
            self.authError = error.localizedDescription
        }
        #else
        // Mock fallback when FirebaseAuth is not linked
        try? await Task.sleep(nanoseconds: 300_000_000)
        self.currentUser = User(id: UUID().uuidString, name: email.components(separatedBy: "@").first ?? "User", email: email)
        self.authError = nil
        #endif
    }

    @MainActor
    func signOut() {
        #if canImport(FirebaseAuth)
        do { try Auth.auth().signOut() } catch {
            self.authError = error.localizedDescription
        }
        #endif
        currentUser = nil
    }

    @MainActor
    func signUp(name: String, email: String, password: String) async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            self.authError = "Please fill all fields."
            return
        }
        isAuthenticating = true
        defer { isAuthenticating = false }
        #if canImport(FirebaseAuth)
        do {
            let authResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<AuthDataResult, Error>) in
                Auth.auth().createUser(withEmail: email, password: password) { result, error in
                    if let error = error { continuation.resume(throwing: error) }
                    else if let result = result { continuation.resume(returning: result) }
                }
            }
            // Set display name
            if let user = authResult.user as User? { /* shadowing avoid */ }
            let change = Auth.auth().currentUser?.createProfileChangeRequest()
            change?.displayName = name
            try? await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                change?.commitChanges { error in
                    if let error = error { c.resume(throwing: error) } else { c.resume() }
                }
            }
            self.authError = nil
        } catch {
            self.authError = error.localizedDescription
        }
        #else
        // Mock fallback when FirebaseAuth is not linked
        try? await Task.sleep(nanoseconds: 300_000_000)
        self.currentUser = User(id: UUID().uuidString, name: name, email: email)
        self.authError = nil
        #endif
    }
}

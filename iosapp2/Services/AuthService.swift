import Foundation
import Combine
import UIKit
#if canImport(FirebaseAuth)
import FirebaseAuth
#endif
#if canImport(FirebaseFirestore)
import FirebaseFirestore
#endif

final class AuthService: ObservableObject {
    @Published private(set) var currentUser: User? = nil
    @Published private(set) var isAuthenticating: Bool = false
    @Published var authError: String? = nil

    #if canImport(FirebaseAuth)
    private var authHandle: AuthStateDidChangeListenerHandle?
    #endif

    private let userRepository: UserRepository = CoreDataUserRepository()

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
        do {
            try await Task.sleep(nanoseconds: 100_000_000)
            if let user = try userRepository.authenticate(email: email, password: password) {
                self.currentUser = user
                self.authError = nil
            } else {
                self.authError = "Invalid credentials."
            }
        } catch {
            self.authError = error.localizedDescription
        }
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
            // Create user profile document in Firestore (optional but useful)
            #if canImport(FirebaseFirestore)
            if let uid = Auth.auth().currentUser?.uid {
                let db = Firestore.firestore()
                let data: [String: Any] = [
                    "name": name,
                    "email": email,
                    "createdAt": Timestamp(date: Date())
                ]
                try? await withCheckedThrowingContinuation { (c: CheckedContinuation<Void, Error>) in
                    db.collection("users").document(uid).setData(data) { error in
                        if let error = error { c.resume(throwing: error) } else { c.resume() }
                    }
                }
            }
            #endif
            self.authError = nil
        } catch {
            self.authError = error.localizedDescription
        }
        #else
        do {
            try await Task.sleep(nanoseconds: 100_000_000)
            let user = try userRepository.createUser(name: name, email: email, password: password)
            self.currentUser = user
            self.authError = nil
        } catch {
            self.authError = error.localizedDescription
        }
        #endif
    }

    func updateProfileImage(_ image: UIImage?) {
        guard let current = currentUser, let uuid = UUID(uuidString: current.id) else { return }
        do {
            try userRepository.updateImage(userId: uuid, image: image)
        } catch {
        }
    }

    func loadProfileImage() -> UIImage? {
        guard let current = currentUser, let uuid = UUID(uuidString: current.id) else { return nil }
        return try? userRepository.loadImage(userId: uuid)
    }
}

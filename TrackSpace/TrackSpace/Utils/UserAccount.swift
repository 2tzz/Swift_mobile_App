import Foundation
import UIKit

struct UserAccount: Codable {
    var name: String
    var email: String
    var phone: String?
    var imagePath: String?
}

enum UserAccountStore {
    private static let key = "userAccount"

    static var current: UserAccount? {
        get {
            guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
            let dec = JSONDecoder()
            return try? dec.decode(UserAccount.self, from: data)
        }
        set {
            let enc = JSONEncoder()
            if let val = newValue, let d = try? enc.encode(val) {
                UserDefaults.standard.set(d, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }

    static var isLoggedIn: Bool { current != nil }

    static func signIn(email: String, password: String) -> Bool {
        // Simple dummy auth: accept any non-empty password; create account if none
        guard !email.isEmpty && !password.isEmpty else { return false }
        if var acct = current {
            acct.email = email
            current = acct
            return true
        } else {
            // create a minimal account with email
            let acct = UserAccount(name: "", email: email, phone: nil, imagePath: nil)
            current = acct
            return true
        }
    }

    static func signOut() {
        current = nil
    }

    static func register(email: String, password: String, name: String, phone: String?, imagePath: String?) -> Bool {
        // Basic register implementation: create and persist the account locally.
        guard !email.isEmpty && !password.isEmpty else { return false }
        let acct = UserAccount(name: name, email: email, phone: phone, imagePath: imagePath)
        current = acct
        return true
    }
}

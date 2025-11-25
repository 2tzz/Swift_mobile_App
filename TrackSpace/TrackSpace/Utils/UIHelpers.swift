import UIKit

/// Helper to dismiss keyboard / resign first responder
func dismissKeyboard() {
    DispatchQueue.main.async {
        UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

extension Notification.Name {
    /// Posted when an image (class/profile/etc) is saved locally.
    static let imageSaved = Notification.Name("ImageSaved")
}

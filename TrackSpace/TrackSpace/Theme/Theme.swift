import SwiftUI

enum Theme {
    // Primary gradient colors inspired by the reference (sky blue/aqua)
    static let primaryStart = Color(red: 0.16, green: 0.67, blue: 0.96) // #29ABF4
    static let primaryEnd   = Color(red: 0.30, green: 0.87, blue: 0.83) // #4DE0D3

    // Neutrals
    static let surface      = Color.white
    static let surfaceAlt   = Color(white: 0.97)
    static let border       = Color.black.opacity(0.06)
    static let shadow       = Color.black.opacity(0.12)

    // Text
    static let textPrimary   = Color.black.opacity(0.85)
    static let textSecondary = Color.black.opacity(0.55)

    // Gradients
    static var headerGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [primaryStart, primaryEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

import SwiftUI

enum Theme {
    // Core palette
    static let primaryStart = Color(red: 0.34, green: 0.62, blue: 1.00) // vibrant azure
    static let primaryEnd   = Color(red: 0.20, green: 0.93, blue: 0.77) // tropical teal
    static let accentStart  = Color(red: 0.98, green: 0.53, blue: 0.90) // magenta glow
    static let accentEnd    = Color(red: 1.00, green: 0.72, blue: 0.47) // amber highlight

    // Backgrounds
    static let backgroundTop    = Color(red: 0.04, green: 0.06, blue: 0.14)
    static let backgroundBottom = Color(red: 0.07, green: 0.12, blue: 0.26)

    // Neutrals / glass surfaces
    static let surface      = Color.white.opacity(0.08)
    static let surfaceAlt   = Color.white.opacity(0.12)
    static let border       = Color.white.opacity(0.18)
    static let shadow       = Color.black.opacity(0.45)

    // Text
    static let textPrimary   = Color.white
    static let textSecondary = Color.white.opacity(0.75)

    // Status
    static let success = Color(red: 0.38, green: 0.87, blue: 0.66)
    static let warning = Color(red: 1.00, green: 0.73, blue: 0.37)

    // Gradients / helpers
    static var headerGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [primaryStart, primaryEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var backgroundGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [backgroundTop, backgroundBottom]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var accentGradient: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [accentStart, accentEnd]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var cardBackground: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.18), Color.white.opacity(0.05)]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var cardStroke: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.45), Color.white.opacity(0.08)]), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static var chipBackground: LinearGradient {
        LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.04)]), startPoint: .top, endPoint: .bottom)
    }
}

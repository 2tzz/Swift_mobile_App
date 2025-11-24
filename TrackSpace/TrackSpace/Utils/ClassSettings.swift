import Foundation
import UIKit

enum ClassSettings {
    private static let thresholdKey = "detectionConfidenceThreshold"
    private static let presetKey = "classPreset"

    static var detectionThreshold: Double {
        get {
            let v = UserDefaults.standard.double(forKey: thresholdKey)
            return v == 0 ? 0.5 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: thresholdKey) }
    }

    static func isEnabled(label: String) -> Bool {
        let key = "classEnabled_\(label)"
        if UserDefaults.standard.object(forKey: key) == nil { return true }
        return UserDefaults.standard.bool(forKey: key)
    }
    static func setEnabled(_ on: Bool, for label: String) {
        let key = "classEnabled_\(label)"
        UserDefaults.standard.set(on, forKey: key)
    }

    static func classImageURLString(for label: String) -> String? {
        let key = "classImage_\(label)"
        return UserDefaults.standard.string(forKey: key)
    }
    static func setClassImageURLString(_ s: String?, for label: String) {
        let key = "classImage_\(label)"
        if let s = s { UserDefaults.standard.set(s, forKey: key) }
        else { UserDefaults.standard.removeObject(forKey: key) }
    }

    // Presets support
    enum Preset: String, CaseIterable {
        case custom = "Custom"
        case home = "Home Items"
        case vehicles = "Vehicles"
        case foods = "Foods"
        case living = "Living Things"
        var title: String {
            switch self {
            case .custom: return "Custom"
            case .home: return "Home"
            case .vehicles: return "Vehicles"
            case .foods: return "Foods"
            case .living: return "Living"
            }
        }
    }

    // Basic mapping from common COCO class names to presets
    private static let presetMap: [Preset: Set<String>] = {
        let home: [String] = ["chair","couch","potted plant","bed","dining table","toilet","laptop","mouse","keyboard","remote","microwave","oven","toaster","refrigerator","bottle","wine glass","cup","fork","knife","spoon","bowl","book","clock","vase","scissors","teddy bear","hair drier","toothbrush","sink"]
        let vehicles: [String] = ["bicycle","car","motorcycle","airplane","bus","train","truck","boat"]
        let foods: [String] = ["banana","apple","sandwich","orange","broccoli","carrot","hot dog","pizza","donut","cake"]
        let living: [String] = ["person","bird","cat","dog","horse","sheep","cow","elephant","bear","zebra","giraffe"]
        return [
            .home: Set(home),
            .vehicles: Set(vehicles),
            .foods: Set(foods),
            .living: Set(living)
        ]
    }()

    static var selectedPreset: Preset {
        get {
            if let raw = UserDefaults.standard.string(forKey: presetKey), let p = Preset(rawValue: raw) { return p }
            return .custom
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: presetKey) }
    }

    static func applyPreset(_ preset: Preset, availableClasses: [String]) {
        // If preset is custom, do nothing
        guard preset != .custom else { return }
        let allowed = presetMap[preset] ?? []
        // enable classes that are in allowed set, disable others
        for cls in availableClasses {
            let enabled = allowed.contains(cls)
            setEnabled(enabled, for: cls)
        }
        selectedPreset = preset
    }
}

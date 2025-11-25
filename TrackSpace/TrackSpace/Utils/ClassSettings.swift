import Foundation
import UIKit

enum ClassSettings {
    private static let thresholdKey = "detectionConfidenceThreshold"
    private static let presetKey = "classPreset"
    private static let assetImageMap: [String: String] = [
        "person": "1_person",
        "bicycle": "2_bicycle",
        "car": "3_car",
        "motorcycle": "4_motorcycle",
        "airplane": "5_plane",
        "plane": "5_plane",
        "bus": "6_bus",
        "train": "7_train",
        "bottle": "bottle",
        "couch": "couch",
        "sofa": "couch",
        "chair": "chair",
        "cup": "cup",
        "cup.jpg": "cup",
        "cup jpeg": "cup",
        "cup jpg": "cup",
        "dining table": "dinig_table",
        "potted plant": "potted plant",
        "plant": "potted plant",
        "vase": "vase",
        "bowl": "bowl",
        "clock": "clock",
        "laptop": "laptop"
    ]

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

    /// Returns a UIImage for the given class label, generating and caching
    /// a simple default image if one does not already exist.
    static func classImage(for label: String) -> UIImage? {
        // If we already have a stored image, load and return it.
        if let url = storedImageURL(for: label), let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
            return ui
        }

        // Use asset catalog image if provided
        if let asset = assetImage(for: label) {
            return asset
        }

        // Otherwise, create a default, save it via ImageStore, and remember its path.
        guard let generated = generateDefaultImage(for: label),
              let url = try? ImageStore.save(generated, name: "class_auto_\(safeFileComponent(from: label))") else {
            return nil
        }
        setClassImageURLString(url.path, for: label)
        return generated
    }

    // Presets support
    enum Preset: String, CaseIterable {
        case custom = "Custom"
        case all = "All Classes"
        case home = "Home Items"
        case vehicles = "Vehicles"
        case foods = "Foods"
        case living = "Living Things"
        var title: String {
            switch self {
            case .custom: return "Custom"
            case .all: return "All Classes"
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
        
        // Special case: "All Classes" enables everything
        if preset == .all {
            for cls in availableClasses {
                setEnabled(true, for: cls)
            }
            selectedPreset = preset
            return
        }
        
        let allowed = presetMap[preset] ?? []
        // enable classes that are in allowed set, disable others
        for cls in availableClasses {
            let enabled = allowed.contains(cls)
            setEnabled(enabled, for: cls)
        }
        selectedPreset = preset
    }

    // MARK: - Private helpers for default class images

    private static func storedImageURL(for label: String) -> URL? {
        guard let s = classImageURLString(for: label) else { return nil }
        if s.hasPrefix("file://"), let url = URL(string: s) {
            return url
        }
        return URL(fileURLWithPath: s)
    }

    private static func generateDefaultImage(for label: String) -> UIImage? {
        let size = CGSize(width: 256, height: 256)
        let scale: CGFloat = 2
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        // Derive a stable color from the label string
        let color = colorForLabel(label)
        let rect = CGRect(origin: .zero, size: size)

        // Rounded rect background
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: 12, dy: 12), cornerRadius: 40)
        ctx.setFillColor(color.cgColor)
        ctx.addPath(path.cgPath)
        ctx.fillPath()

        // Subtle inner highlight
        let highlight = UIColor.white.withAlphaComponent(0.14)
        let inner = UIBezierPath(roundedRect: rect.insetBy(dx: 18, dy: 24), cornerRadius: 30)
        ctx.setStrokeColor(highlight.cgColor)
        ctx.setLineWidth(2)
        ctx.addPath(inner.cgPath)
        ctx.strokePath()

        // First character / short label in the center
        let initial = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "?" : String(label.prefix(1)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 120, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        let textSize = (initial as NSString).size(withAttributes: attrs)
        let textRect = CGRect(
            x: rect.midX - textSize.width / 2,
            y: rect.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        (initial as NSString).draw(in: textRect, withAttributes: attrs)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    private static func colorForLabel(_ label: String) -> UIColor {
        // Simple deterministic hash -> hue mapping
        var hasher = Hasher()
        hasher.combine(label)
        let hash = hasher.finalize()
        let hue = CGFloat((abs(hash) % 256)) / 255.0
        return UIColor(hue: hue, saturation: 0.65, brightness: 0.95, alpha: 1.0)
    }

    private static func safeFileComponent(from label: String) -> String {
        let invalid = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_")).inverted
        return label.components(separatedBy: invalid).joined(separator: "_")
    }

    private static func assetImage(for label: String) -> UIImage? {
        let key = label.lowercased()
        if let assetName = assetImageMap[key], let image = UIImage(named: assetName) {
            return image
        }
        // attempt direct lookup using label or sanitized variations
        if let direct = UIImage(named: label) {
            return direct
        }
        let sanitized = key.replacingOccurrences(of: " ", with: "_")
        if let under = UIImage(named: sanitized) {
            return under
        }
        return nil
    }
}

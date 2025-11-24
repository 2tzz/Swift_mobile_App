import Foundation
import UIKit

enum ImageStore {
    static func save(_ image: UIImage, name: String = UUID().uuidString) throws -> URL {
        let url = try directory().appendingPathComponent("\(name).jpg")
        guard let data = image.jpegData(compressionQuality: 0.9) else {
            throw NSError(domain: "ImageStore", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode JPEG"])
        }
        try data.write(to: url, options: .atomic)
        // debug log saved path
        print("ImageStore: saved image to \(url.path)")
        return url
    }

    static func directory() throws -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let subdir = dir.appendingPathComponent("AssetScanImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: subdir.path) {
            try FileManager.default.createDirectory(at: subdir, withIntermediateDirectories: true)
        }
        return subdir
    }
}

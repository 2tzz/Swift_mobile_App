import Foundation
import CoreGraphics

struct Detection: Identifiable, Hashable {
    let id: UUID
    var label: String
    var rect: CGRect // normalized [0,1] rect in image coordinates (origin top-left)
    var confidence: Float

    init(id: UUID = UUID(), label: String, rect: CGRect, confidence: Float) {
        self.id = id
        self.label = label
        self.rect = rect
        self.confidence = confidence
    }
}

extension Array where Element == Detection {
    func groupedCounts() -> [(label: String, count: Int)] {
        let counts = Dictionary(grouping: self, by: { $0.label }).mapValues { $0.count }
        return counts.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }
}

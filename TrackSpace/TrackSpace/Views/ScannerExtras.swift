import SwiftUI
import CoreData

extension ScannerView {
    func quickSave(detections: [Detection], image: UIImage, location: String) {
        let context = AssetScanStore.shared.container.viewContext
        // filter by confidence >= 0.5
        let filtered = detections.filter { Double($0.confidence) >= 0.5 }
        guard !filtered.isEmpty else {
            // Can't access showSavedBanner/saveMessage here; post notification instead
            NotificationCenter.default.post(name: .inventoryChanged, object: nil)
            return
        }
        do {
            let date = Date()
            // Find or create Room with this location name
            let roomFetch: NSFetchRequest<Room> = NSFetchRequest(entityName: "Room")
            roomFetch.predicate = NSPredicate(format: "name == %@", location)
            let rooms = try context.fetch(roomFetch)
            let room: Room
            if let existing = rooms.first {
                room = existing
            } else {
                room = NSEntityDescription.insertNewObject(forEntityName: "Room", into: context) as! Room
                room.id = UUID()
                room.name = location
                room.date = date
            }

            // Group detections by label, pick highest-confidence detection for each label
            let grouped = Dictionary(grouping: filtered, by: { $0.label })
            var summaryDict: [String: Int] = [:]

            for (label, group) in grouped {
                let best = group.max { a, b in a.confidence < b.confidence }!
                // Save one image per label (from highest confidence). Use label+UUID to avoid collisions.
                let imageURL = try ImageStore.save(image, name: "\(label)_\(UUID().uuidString)")

                let item = NSEntityDescription.insertNewObject(forEntityName: "InventoryItem", into: context) as! InventoryItem
                item.id = UUID()
                item.label = label
                item.x = best.rect.origin.x
                item.y = best.rect.origin.y
                item.width = best.rect.size.width
                item.height = best.rect.size.height
                item.imageURL = imageURL.absoluteString
                item.location = location
                item.date = date
                item.count = Int64(group.count)
                item.room = room

                summaryDict[label] = group.count
            }

            try context.save()

            NotificationCenter.default.post(name: .inventoryChanged, object: nil)
        } catch {
            print("quickSave error: \(error)")
        }
    }
}

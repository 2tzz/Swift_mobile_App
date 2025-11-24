import SwiftUI
import CoreData
import UIKit

struct InventoryView: View {
    @State private var items: [InventoryItem] = []
    private var context: NSManagedObjectContext { AssetScanStore.shared.container.viewContext }

    var body: some View {
        List {
            ForEach(grouped(), id: \.key) { loc, arr in
                Section(header: Text(loc)) {
                    ForEach(arr, id: \.id) { item in
                        HStack(alignment: .top, spacing: 12) {
                            if let url = URL(string: item.imageURL),
                               let data = try? Data(contentsOf: url),
                               let ui = UIImage(data: data) {
                                let thumb = crop(image: ui, rect: CGRect(x: item.x, y: item.y, width: item.width, height: item.height))
                                Image(uiImage: thumb)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 56, height: 56)
                                    .clipped()
                                    .cornerRadius(8)
                            }
                            VStack(alignment: .leading) {
                                Text(item.label).font(.headline)
                                Text(item.date, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Inventory")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Seed Samples") { seedSamples() }
            }
        }
        .onAppear { reload() }
    }

    private func reload() {
        let req = InventoryItem.fetchRequestAll()
        do { items = try context.fetch(req) } catch { items = [] }
    }

    private func grouped() -> [(key: String, value: [InventoryItem])] {
        let dict = Dictionary(grouping: items, by: { $0.location })
        return dict.sorted { $0.key < $1.key }
    }

    private func crop(image: UIImage, rect: CGRect) -> UIImage {
        let w = CGFloat(image.cgImage!.width)
        let h = CGFloat(image.cgImage!.height)
        let r = CGRect(x: rect.origin.x * w, y: rect.origin.y * h, width: rect.size.width * w, height: rect.size.height * h)
        guard let cg = image.cgImage?.cropping(to: r) else { return image }
        return UIImage(cgImage: cg)
    }

    private func seedSamples() {
        // Create a simple test image and insert several sample items.
        let size = CGSize(width: 800, height: 600)
        UIGraphicsBeginImageContextWithOptions(size, true, 1)
        UIColor.systemGray5.setFill()
        UIRectFill(CGRect(origin: .zero, size: size))
        // Draw simple rectangles as pseudo objects
        UIColor.systemBlue.setFill(); UIRectFill(CGRect(x: 80, y: 120, width: 220, height: 140))
        UIColor.systemGreen.setFill(); UIRectFill(CGRect(x: 420, y: 300, width: 160, height: 180))
        UIColor.systemOrange.setFill(); UIRectFill(CGRect(x: 300, y: 100, width: 120, height: 100))
        let baseImage = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()

        do {
            let url = try ImageStore.save(baseImage, name: "sample_\(UUID().uuidString)")
            let date = Date()

            func normRect(x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> CGRect {
                CGRect(x: x/size.width, y: y/size.height, width: w/size.width, height: h/size.height)
            }

            let samples: [(String, String, CGRect)] = [
                ("Chair", "Office", normRect(x: 80, y: 120, w: 220, h: 140)),
                ("Laptop", "Office", normRect(x: 420, y: 300, w: 160, h: 180)),
                ("Monitor", "Living Room", normRect(x: 300, y: 100, w: 120, h: 100))
            ]

            for (label, location, rect) in samples {
                let item = NSEntityDescription.insertNewObject(forEntityName: "InventoryItem", into: context) as! InventoryItem
                item.id = UUID()
                item.label = label
                item.x = rect.origin.x
                item.y = rect.origin.y
                item.width = rect.size.width
                item.height = rect.size.height
                item.imageURL = url.absoluteString
                item.location = location
                item.date = date
            }
            try context.save()
            reload()
        } catch {
            print("Seed error: \(error)")
        }
    }
}

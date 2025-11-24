import SwiftUI
import CoreData
import UIKit

struct InventoryView: View {
    @State private var items: [InventoryItem] = []
    @State private var showAccount: Bool = false
    private var context: NSManagedObjectContext { AssetScanStore.shared.container.viewContext }
    @State private var deletingLocation: String? = nil
    @State private var showDeleteLocationAlert = false

    var body: some View {
        VStack {
            List {
            ForEach(grouped(), id: \.key) { loc, arr in
                Section(header: HStack {
                    Text(loc)
                    Spacer()
                    Button(role: .destructive) {
                        deletingLocation = loc
                        showDeleteLocationAlert = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                }) {
                    ForEach(arr, id: \.id) { item in
                        HStack(alignment: .top, spacing: 12) {
                            // Prefer user-provided class image for consistency; fallback to cropped thumbnail
                            if let classURLStr = ClassSettings.classImageURLString(for: item.label) {
                                if let classURL = fileURL(from: classURLStr), let data2 = try? Data(contentsOf: classURL), let ui2 = UIImage(data: data2) {
                                    Image(uiImage: ui2)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            } else if let url = URL(string: item.imageURL), let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
                                let thumb = crop(image: ui, rect: CGRect(x: item.x, y: item.y, width: item.width, height: item.height))
                                    Image(uiImage: thumb)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipped()
                                        .cornerRadius(8)
                            }
                            VStack(alignment: .leading) {
                                HStack {
                                    Text(item.label).font(.headline)
                                    Spacer()
                                    Text("x\(item.count)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text(item.date, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) { deleteItem(item: item) } label: { Label("Delete", systemImage: "trash") }
                        }
                    }
                }
            }
            }
            .listStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .background(.clear)
        .appCardStyle(cornerRadius: 18, shadowRadius: 10)
        .navigationTitle("Inventory")
        .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // hide keyboard before presenting account sheet
                    dismissKeyboard()
                    showAccount = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .foregroundStyle(Theme.primaryStart)
                }
            }
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack { AccountView() }
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .inventoryChanged)) { _ in reload() }
        .alert(isPresented: $showDeleteLocationAlert) { confirmDeleteLocationIfNeeded() }
        .background(Theme.headerGradient.ignoresSafeArea())
    }

    private func reload() {
        let req = InventoryItem.fetchRequestAll()
        do { items = try context.fetch(req) } catch { items = [] }
    }

    private func grouped() -> [(key: String, value: [InventoryItem])] {
        let dict = Dictionary(grouping: items, by: { $0.location })
        return dict.sorted { $0.key < $1.key }
    }

    // Alert for delete location
    private func confirmDeleteLocationIfNeeded() -> Alert {
        Alert(
            title: Text("Delete Location"),
            message: Text("Delete all items for \(deletingLocation ?? "this location")? This cannot be undone."),
            primaryButton: .destructive(Text("Delete")) {
                if let loc = deletingLocation { deleteLocation(loc) }
                deletingLocation = nil
            },
            secondaryButton: .cancel() {
                deletingLocation = nil
            }
        )
    }

    private func crop(image: UIImage, rect: CGRect) -> UIImage {
        let w = CGFloat(image.cgImage!.width)
        let h = CGFloat(image.cgImage!.height)
        let r = CGRect(x: rect.origin.x * w, y: rect.origin.y * h, width: rect.size.width * w, height: rect.size.height * h)
        guard let cg = image.cgImage?.cropping(to: r) else { return image }
        return UIImage(cgImage: cg)
    }

    // Helper to convert saved class image identifier into a file URL.
    // Accepts either a file system path or a file:// absolute string.
    private func fileURL(from saved: String) -> URL? {
        if saved.hasPrefix("file://") { return URL(string: saved) }
        return URL(fileURLWithPath: saved)
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
                item.count = 1
                item.date = date
            }
            try context.save()
            reload()
        } catch {
            print("Seed error: \(error)")
        }
    }

    // MARK: - Item manipulation
    private func saveContext() {
        do { try context.save(); reload() } catch { print("Save error: \(error)") }
    }

    private func increment(item: InventoryItem) {
        item.count += 1
        item.date = Date()
        saveContext()
    }

    private func decrement(item: InventoryItem) {
        if item.count > 1 {
            item.count -= 1
            item.date = Date()
            saveContext()
        } else {
            // remove item if count goes to zero
            deleteItem(item: item)
        }
    }

    private func deleteItem(item: InventoryItem) {
        withAnimation(.easeInOut) {
            context.delete(item)
            saveContext()
        }
    }

    private func deleteLocation(_ location: String) {
        let req: NSFetchRequest<InventoryItem> = NSFetchRequest(entityName: "InventoryItem")
        req.predicate = NSPredicate(format: "location == %@", location)
        do {
            let toDelete = try context.fetch(req)
            for it in toDelete { context.delete(it) }
            // Also remove Room entity if exists
            let roomReq: NSFetchRequest<Room> = NSFetchRequest(entityName: "Room")
            roomReq.predicate = NSPredicate(format: "name == %@", location)
            let rooms = try context.fetch(roomReq)
            for r in rooms { context.delete(r) }
            saveContext()
        } catch {
            print("Delete location error: \(error)")
        }
    }

}

                

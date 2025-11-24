import SwiftUI
import CoreData
import UIKit

struct InventoryView: View {
    @State private var items: [InventoryItem] = []
    @State private var showAccount: Bool = false
    private var context: NSManagedObjectContext { AssetScanStore.shared.container.viewContext }
    @State private var deletingLocation: String? = nil
    @State private var showDeleteLocationAlert = false
    @State private var expandedLocations: Set<String> = []
    @Namespace private var expandNamespace

    var body: some View {
        ZStack(alignment: .top) {
            Theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    summaryCard

                    if items.isEmpty {
                        GlassCard {
                            VStack(spacing: 10) {
                                Image(systemName: "shippingbox")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundStyle(Theme.textSecondary)
                                Text("No items yet")
                                    .font(.headline)
                                    .foregroundStyle(Theme.textPrimary)
                                Text("Start a scan to populate your inventory.")
                                    .font(.subheadline)
                                    .foregroundStyle(Theme.textSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(grouped(), id: \.key) { loc, arr in
                            locationCard(location: loc, items: arr)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 28)
                .padding(.bottom, 80)
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    dismissKeyboard()
                    showAccount = true
                } label: {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Theme.textPrimary)
                }
            }
        }
        .sheet(isPresented: $showAccount) {
            NavigationStack { AccountView() }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.clear, for: .navigationBar)
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .inventoryChanged)) { _ in reload() }
        .alert(isPresented: $showDeleteLocationAlert) { confirmDeleteLocationIfNeeded() }
    }

    private var summaryCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("Inventory Overview")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                Text("\(items.count) tracked variants • \(uniqueLocations) locations")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func reload() {
        let req = InventoryItem.fetchRequestAll()
        do { items = try context.fetch(req) } catch { items = [] }
    }

    private func grouped() -> [(key: String, value: [InventoryItem])] {
        let dict = Dictionary(grouping: items, by: { $0.location })
        return dict.sorted { $0.key < $1.key }
    }

    private var uniqueLocations: Int {
        Set(items.map { $0.location }).count
    }

    private func totalCount(for items: [InventoryItem]) -> Int {
        items.reduce(0) { $0 + Int($1.count) }
    }

    private func locationCard(location: String, items: [InventoryItem]) -> some View {
        let isExpanded = expandedLocations.contains(location)
        return GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(location)
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text("\(items.count) categories • \(totalCount(for: items)) items")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Button {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            toggleLocation(location)
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                    }
                    Button {
                        deletingLocation = location
                        showDeleteLocationAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.red.opacity(0.8))
                }

                VStack(spacing: 10) {
                    if isExpanded {
                        ForEach(items, id: \.id) { item in
                            itemRow(item)
                                .transition(.asymmetric(insertion: .opacity.combined(with: .scale(scale: 0.98)).combined(with: .move(edge: .top)), removal: .opacity))
                        }
                    }
                }
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isExpanded)
            }
        }
    }

    private func itemRow(_ item: InventoryItem) -> some View {
        HStack(spacing: 14) {
            itemThumbnail(for: item)
                .frame(width: 58, height: 58)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.label)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text(item.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                Text("x\(item.count)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.chipBackground)
                    .clipShape(Capsule())

                Button {
                    deleteItem(item: item)
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func itemThumbnail(for item: InventoryItem) -> some View {
        if let classImage = ClassSettings.classImage(for: item.label) {
            Image(uiImage: classImage)
                .resizable()
                .scaledToFill()
        } else if let url = URL(string: item.imageURL), let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
            let thumb = crop(image: ui, rect: CGRect(x: item.x, y: item.y, width: item.width, height: item.height))
            Image(uiImage: thumb)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                Theme.surface
                Image(systemName: "photo")
                    .foregroundStyle(Theme.textSecondary)
            }
        }
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

    private func toggleLocation(_ location: String) {
        if expandedLocations.contains(location) {
            expandedLocations.remove(location)
        } else {
            expandedLocations.insert(location)
        }
    }

}

                

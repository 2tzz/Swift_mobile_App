import SwiftUI
import CoreData
import UIKit

struct DetectionReviewView: View {
    let image: UIImage
    @State var detections: [Detection]

    @State private var location: String = ""
    @State private var existingLocations: [String] = []
    private var context: NSManagedObjectContext { AssetScanStore.shared.container.viewContext }
    @State private var navigateToInventory = false
    @Environment(\.dismiss) private var dismiss

    init(image: UIImage, initialDetections: [Detection]) {
        self.image = image
        self._detections = State(initialValue: initialDetections)
    }

    var body: some View {
        GeometryReader { geo in
            Group {
                if geo.size.width > 700 {
                    // Side-by-side layout for wide screens
                    HStack(spacing: 16) {
                        imageColumn(width: geo.size.width * 0.6)
                        controlsColumn(width: geo.size.width * 0.4)
                    }
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            imageColumn(width: geo.size.width - 32)
                            controlsColumn(width: geo.size.width - 32)
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Review")
            .onAppear(perform: loadExistingLocations)
            .navigationDestination(isPresented: $navigateToInventory) {
                InventoryView()
            }
        }
    }

    // MARK: - Subviews
    @State private var imageScale: CGFloat = 1.0
    @State private var imageOffset: CGSize = .zero
    @State private var isZoomed: Bool = false

    private func imageColumn(width: CGFloat) -> some View {
        ZStack {
            Color.clear
            GeometryReader { canvas in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(imageScale)
                    .offset(imageOffset)
                    .animation(.spring(), value: imageScale)
                    .gesture(
                        SimultaneousGesture(DragGesture().onChanged { v in
                            imageOffset = CGSize(width: imageOffset.width + v.translation.width, height: imageOffset.height + v.translation.height)
                        }.onEnded { _ in }, MagnificationGesture().onChanged { v in
                            imageScale = v
                        }.onEnded { _ in if imageScale < 1 { withAnimation { imageScale = 1; imageOffset = .zero } } })
                    )
                    .overlay(GeometryReader { geo in
                        ForEach($detections) { $det in
                            BoundingBoxView(rect: $det.rect, label: det.label, imageSize: image.size, canvasSize: geo.size)
                                .animation(.easeInOut, value: det.rect)
                        }
                    })
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            if isZoomed { imageScale = 1; imageOffset = .zero; isZoomed = false }
                            else { imageScale = 2.0; isZoomed = true }
                        }
                    }
            }
            .frame(width: width)
        }
        .appCardStyle()
        .frame(minHeight: 240)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func controlsColumn(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detections").font(.headline)
            ForEach($detections) { $det in
                HStack {
                    TextField("Label", text: $det.label)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: .infinity)
                    Button(role: .destructive) { remove(id: det.id) } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
                .appCardStyle(cornerRadius: 10, shadowRadius: 3)
            }
            if detections.isEmpty {
                Text("No detections. You can go back and rescan.").foregroundStyle(.secondary)
            }

            Divider().padding(.vertical, 6)

            Text("Location").font(.headline)
            HStack {
                Menu {
                    ForEach(existingLocations, id: \ .self) { loc in
                        Button(loc) { location = loc }
                    }
                } label: {
                    Label("Choose Existing", systemImage: "tray.and.arrow.down.fill")
                }
                TextField("e.g., Office, Living Room", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Spacer()

            Button(action: saveToInventory) {
                HStack {
                    Spacer()
                    Text("Add to Inventory")
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding()
                .background(detections.isEmpty || location.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                .cornerRadius(12)
            }
            .disabled(detections.isEmpty || location.isEmpty)
        }
        .frame(width: width)
    }

    private func remove(id: UUID) { detections.removeAll { $0.id == id } }

    private func loadExistingLocations() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "InventoryItem")
        fetch.propertiesToFetch = ["location"]
        fetch.returnsDistinctResults = true
        fetch.resultType = .dictionaryResultType
        do {
            let results = try context.fetch(fetch) as? [[String: Any]] ?? []
            existingLocations = Array(Set(results.compactMap { $0["location"] as? String })).sorted()
        } catch { existingLocations = [] }
    }

    private func saveToInventory() {
        // Save grouped by label: one InventoryItem per label, count = occurrences, image from highest-confidence
        do {
            let date = Date()
            // Group by label
            let grouped = Dictionary(grouping: detections, by: { $0.label })
            for (label, group) in grouped {
                // pick best by confidence
                let best = group.max { a, b in a.confidence < b.confidence }!
                // save cropped image for this label (optional: save full image)
                let baseImage = image
                // crop thumbnail
                var imageURL: URL
                if let cg = baseImage.cgImage {
                    let w = CGFloat(cg.width)
                    let h = CGFloat(cg.height)
                    let r = CGRect(x: best.rect.origin.x * w, y: best.rect.origin.y * h, width: best.rect.size.width * w, height: best.rect.size.height * h)
                    if let cropped = baseImage.cgImage?.cropping(to: r) {
                        let thumb = UIImage(cgImage: cropped)
                        imageURL = try ImageStore.save(thumb, name: "\(label)_\(UUID().uuidString)")
                    } else {
                        imageURL = try ImageStore.save(baseImage)
                    }
                } else {
                    imageURL = try ImageStore.save(baseImage)
                }

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
            }
            try context.save()
            NotificationCenter.default.post(name: .inventoryChanged, object: nil)
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}

private struct BoundingBoxView: View {
    @Binding var rect: CGRect // normalized
    let label: String
    let imageSize: CGSize
    let canvasSize: CGSize

    @State private var dragOffset: CGSize = .zero
    @State private var resizeHandle: CGSize = .zero

    var body: some View {
        let box = denormalized(rect: rect, imageSize: imageSize, canvasSize: canvasSize)
        return ZStack(alignment: .topLeading) {
            Rectangle()
                .stroke(Color.yellow, lineWidth: 2)
                .background(Color.yellow.opacity(0.1))
                .frame(width: box.width, height: box.height)
                .position(x: box.midX, y: box.midY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dx = value.translation.width / canvasSize.width
                            let dy = value.translation.height / canvasSize.height
                            rect.origin.x = clamp(rect.origin.x + dx, 0, 1 - rect.size.width)
                            rect.origin.y = clamp(rect.origin.y + dy, 0, 1 - rect.size.height)
                        }
                )

            Text(label)
                .font(.caption.bold())
                .padding(4)
                .background(.black.opacity(0.6))
                .foregroundColor(.white)
                .offset(x: box.minX, y: box.minY - 22)

            Circle()
                .fill(Color.yellow)
                .frame(width: 18, height: 18)
                .position(x: box.maxX, y: box.maxY)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let dx = max(value.translation.width, -box.width) / canvasSize.width
                            let dy = max(value.translation.height, -box.height) / canvasSize.height
                            rect.size.width = clamp(rect.size.width + dx, 0.02, 1 - rect.origin.x)
                            rect.size.height = clamp(rect.size.height + dy, 0.02, 1 - rect.origin.y)
                        }
                )
        }
    }

    private func denormalized(rect: CGRect, imageSize: CGSize, canvasSize: CGSize) -> CGRect {
        // Letterboxed fit: scaledToFit mapping
        let imageAspect = imageSize.width / imageSize.height
        let canvasAspect = canvasSize.width / canvasSize.height
        var drawSize = CGSize.zero
        if imageAspect > canvasAspect {
            drawSize.width = canvasSize.width
            drawSize.height = canvasSize.width / imageAspect
        } else {
            drawSize.height = canvasSize.height
            drawSize.width = canvasSize.height * imageAspect
        }
        let originX = (canvasSize.width - drawSize.width) / 2
        let originY = (canvasSize.height - drawSize.height) / 2
        let x = originX + rect.origin.x * drawSize.width
        let y = originY + rect.origin.y * drawSize.height
        let w = rect.size.width * drawSize.width
        let h = rect.size.height * drawSize.height
        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func clamp(_ v: CGFloat, _ minV: CGFloat, _ maxV: CGFloat) -> CGFloat { min(max(v, minV), maxV) }
}

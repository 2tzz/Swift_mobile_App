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
    @State private var labelCounts: [String: Int] = [:]

    init(image: UIImage, initialDetections: [Detection]) {
        self.image = image
        self._detections = State(initialValue: initialDetections)
        self._labelCounts = State(initialValue: DetectionReviewView.initialLabelCounts(initialDetections))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Theme.backgroundGradient
                    .ignoresSafeArea()

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
    private var sortedLabels: [String] {
        labelCounts.keys.sorted()
    }

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
            Text("Quantities")
                .font(.headline)
                .foregroundStyle(.white)

            quantityCard

            Text("Location")
                .font(.headline)
                .foregroundStyle(.white)
            HStack(spacing: 12) {
                Menu {
                    ForEach(existingLocations, id: \.self) { loc in
                        Button(loc) { location = loc }
                    }
                } label: {
                    Label("Locations", systemImage: "tray.and.arrow.down.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(gradient: Gradient(colors: [Theme.primaryStart.opacity(0.7), Theme.primaryEnd.opacity(0.6)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                }

                TextField("e.g., Office, Living Room", text: $location)
                    .padding(12)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .foregroundColor(.white)
            }

            Spacer(minLength: 8)

            PrimaryButton(action: saveToInventory) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Add to Inventory")
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .opacity(detections.isEmpty || location.isEmpty ? 0.4 : 1)
            .disabled(detections.isEmpty || location.isEmpty)
        }
        .frame(width: width)
        .appCardStyle()
    }

    private var quantityCard: some View {
        GlassCard {
            VStack(spacing: 12) {
                if sortedLabels.isEmpty {
                    Text("No detections. Return to scan to capture items.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(sortedLabels, id: \.self) { label in
                        quantityRow(label: label, count: labelCounts[label] ?? 0)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: labelCounts)
    }

    private func quantityRow(label: String, count: Int) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 0) {
                Button { adjustCount(for: label, delta: -1) } label: {
                    Image(systemName: "minus")
                        .frame(width: 32, height: 32)
                }
                .disabled(count <= 0)
                .buttonStyle(.plain)

                Text("\(max(count, 0))")
                    .frame(width: 42)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)

                Button { adjustCount(for: label, delta: 1) } label: {
                    Image(systemName: "plus")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }

    private func remove(id: UUID) {
        guard let idx = detections.firstIndex(where: { $0.id == id }) else { return }
        let label = detections[idx].label
        detections.remove(at: idx)
        labelCounts[label] = max(0, (labelCounts[label] ?? 1) - 1)
        labelCounts = labelCounts.filter { $0.value > 0 }
    }

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
                let desiredCount = max(labelCounts[label] ?? group.count, 0)
                guard desiredCount > 0 else { continue }
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
                item.count = Int64(desiredCount)
            }
            try context.save()
            NotificationCenter.default.post(name: .inventoryChanged, object: nil)
            dismiss()
        } catch {
            print("Save error: \(error)")
        }
    }
}

// MARK: - Label count helpers
private extension DetectionReviewView {
    static func initialLabelCounts(_ detections: [Detection]) -> [String: Int] {
        Dictionary(grouping: detections, by: { $0.label }).mapValues { $0.count }
    }

    func adjustCount(for label: String, delta: Int) {
        guard var current = labelCounts[label] else { return }
        current = max(0, min(99, current + delta))
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            if current == 0 {
                labelCounts.removeValue(forKey: label)
            } else {
                labelCounts[label] = current
            }
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

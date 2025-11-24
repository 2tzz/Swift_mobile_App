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

    init(image: UIImage, initialDetections: [Detection]) {
        self.image = image
        self._detections = State(initialValue: initialDetections)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .overlay(GeometryReader { geo in
                            ForEach($detections) { $det in
                                BoundingBoxView(rect: $det.rect, label: det.label, imageSize: image.size, canvasSize: geo.size)
                            }
                        })
                    
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Detections").font(.headline)
                    ForEach($detections) { $det in
                        HStack {
                            TextField("Label", text: $det.label)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Spacer()
                            Button(role: .destructive) { remove(id: det.id) } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                    if detections.isEmpty {
                        Text("No detections. You can go back and rescan.").foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Location").font(.headline)
                    HStack {
                        Menu {
                            ForEach(existingLocations, id: \.self) { loc in
                                Button(loc) { location = loc }
                            }
                        } label: {
                            Label("Choose Existing", systemImage: "tray.and.arrow.down.fill")
                        }
                        TextField("e.g., Office, Living Room", text: $location)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                .padding(.horizontal)

                Button(action: saveToInventory) {
                    Text("Add to Inventory")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(detections.isEmpty || location.isEmpty ? Color.gray.opacity(0.3) : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(detections.isEmpty || location.isEmpty)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Review")
        .onAppear(perform: loadExistingLocations)
        .navigationDestination(isPresented: $navigateToInventory) {
            InventoryView()
        }
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
        do {
            let url = try ImageStore.save(image)
            let date = Date()
            for det in detections {
                let item = NSEntityDescription.insertNewObject(forEntityName: "InventoryItem", into: context) as! InventoryItem
                item.id = det.id
                item.label = det.label
                item.x = det.rect.origin.x
                item.y = det.rect.origin.y
                item.width = det.rect.size.width
                item.height = det.rect.size.height
                item.imageURL = url.absoluteString
                item.location = location
                item.date = date
            }
            try context.save()
            navigateToInventory = true
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

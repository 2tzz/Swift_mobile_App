import SwiftUI
import PhotosUI

struct ClassSettingsView: View {
    @State private var classes: [String] = []
    @State private var threshold: Double = ClassSettings.detectionThreshold
    @State private var pickLabelForImage: String? = nil
    @State private var isPickingImage = false
    @State private var selectedPreset: ClassSettings.Preset = ClassSettings.selectedPreset

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Presets")) {
                    Picker("Preset", selection: $selectedPreset) {
                        ForEach(ClassSettings.Preset.allCases, id: \.self) { p in
                            Text(p.title).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedPreset) { p in
                        if p != .custom {
                            ClassSettings.applyPreset(p, availableClasses: classes)
                        }
                        ClassSettings.selectedPreset = p
                        // reload toggles
                        classes = YOLODetector.shared.availableClassNames
                    }
                }

                Section(header: Text("Detection Threshold")) {
                    VStack(alignment: .leading) {
                        Slider(value: $threshold, in: 0...1, step: 0.01) {
                            Text("Threshold")
                        }
                        Text(String(format: "%.0f%%", threshold * 100))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .onChange(of: threshold) { v in ClassSettings.detectionThreshold = v }
                }

                Section(header: Text("Classes")) {
                    ForEach(classes, id: \.self) { label in
                        HStack {
                            Toggle(isOn: Binding(get: { ClassSettings.isEnabled(label: label) }, set: { val in withAnimation { ClassSettings.setEnabled(val, for: label); selectedPreset = .custom; ClassSettings.selectedPreset = .custom } })) {
                                Text(label)
                            }
                            Spacer()
                            if let s = ClassSettings.classImageURLString(for: label), let url = fileURL(from: s), let data = try? Data(contentsOf: url), let ui = UIImage(data: data) {
                                Image(uiImage: ui)
                                    .resizable()
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: "photo")
                                    .frame(width: 36, height: 36)
                            }

                            Button("Change") {
                                // dismiss any keyboard first to avoid keyboard/layout constraint conflicts
                                dismissKeyboard()
                                pickLabelForImage = label
                                isPickingImage = true
                            }
                        }
                        .padding(8)
                        .appCardStyle()
                        .animation(.default, value: ClassSettings.classImageURLString(for: label))
                    }
                }
            }
            .navigationTitle("Class Settings")
            .onAppear(perform: load)
            .sheet(isPresented: $isPickingImage) {
                    if let label = pickLabelForImage {
                    ImagePicker { image in
                        if let img = image {
                            // sanitize label to create a safe filename
                            let safe = label.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
                            let fileName = "class_\(safe)"
                            if let url = try? ImageStore.save(img, name: fileName) {
                                // store file system path for reliable local loading
                                ClassSettings.setClassImageURLString(url.path, for: label)
                                print("ClassSettingsView: saved class image for \(label) -> \(url.path)")
                                // notify app to show a small toast/banner
                                NotificationCenter.default.post(name: .imageSaved, object: nil, userInfo: ["path": url.path, "label": label])
                                load()
                            } else {
                                print("ClassSettingsView: failed to save image for class \(label)")
                            }
                        }
                        isPickingImage = false
                    }
                } else { EmptyView() }
            }
        }
    }

    private func load() {
        classes = YOLODetector.shared.availableClassNames
        threshold = ClassSettings.detectionThreshold
    }

    // Helper to convert saved class image identifier into a file URL.
    // Accepts either a file system path or a file:// absolute string.
    private func fileURL(from saved: String) -> URL? {
        if saved.hasPrefix("file://") { return URL(string: saved) }
        // Try to treat as absolute file path
        let candidate = URL(fileURLWithPath: saved)
        if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
        // Fallback: maybe it's an absolute URL string
        if let url = URL(string: saved), FileManager.default.fileExists(atPath: url.path) { return url }
        return nil
    }
}

// Simple PHPicker wrapper returning UIImage
private struct ImagePicker: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var cfg = PHPickerConfiguration(photoLibrary: .shared())
        cfg.filter = .images
        cfg.selectionLimit = 1
        let pc = PHPickerViewController(configuration: cfg)
        pc.delegate = context.coordinator
        return pc
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(completion: completion) }
    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let completion: (UIImage?) -> Void
        init(completion: @escaping (UIImage?) -> Void) { self.completion = completion }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let first = results.first else { completion(nil); return }
            if first.itemProvider.canLoadObject(ofClass: UIImage.self) {
                first.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in DispatchQueue.main.async { self.completion(obj as? UIImage) } }
            } else { completion(nil) }
        }
    }
}

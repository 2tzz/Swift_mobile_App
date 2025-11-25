import SwiftUI
import PhotosUI

struct ClassSettingsView: View {
    @State private var classes: [String] = []
    @State private var threshold: Double = ClassSettings.detectionThreshold
    @State private var pickLabelForImage: String? = nil
    @State private var isPickingImage = false
    @State private var selectedPreset: ClassSettings.Preset = ClassSettings.selectedPreset

    var body: some View {
        ZStack {
            Theme.backgroundGradient
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    presetsCard
                    thresholdCard
                    classesCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 28)
            }
        }
        .navigationTitle("")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.clear, for: .navigationBar)
        .onAppear(perform: load)
        .sheet(isPresented: $isPickingImage) {
            if let label = pickLabelForImage {
                ImagePicker { image in
                    if let img = image {
                        let safe = label.replacingOccurrences(of: "[^A-Za-z0-9_-]", with: "_", options: .regularExpression)
                        let fileName = "class_\(safe)"
                        if let url = try? ImageStore.save(img, name: fileName) {
                            ClassSettings.setClassImageURLString(url.path, for: label)
                            print("ClassSettingsView: saved class image for \(label) -> \(url.path)")
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

    private var presetsCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Presets")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                Picker("Preset", selection: $selectedPreset) {
                    ForEach(ClassSettings.Preset.allCases, id: \.self) { p in
                        Text(p.title).tag(p)
                    }
                }
                .pickerStyle(.menu)
                .tint(Theme.primaryStart)
                .onChange(of: selectedPreset) { p in
                    if p != .custom {
                        ClassSettings.applyPreset(p, availableClasses: classes)
                    }
                    ClassSettings.selectedPreset = p
                    classes = YOLODetector.shared.availableClassNames
                }
                Text("Quickly enable sets of objects or fall back to Custom for manual control.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var thresholdCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Detection Threshold")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Text(String(format: "%.0f%%", threshold * 100))
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Theme.chipBackground)
                        .clipShape(Capsule())
                }
                Slider(value: $threshold, in: 0...1, step: 0.01)
                    .tint(Theme.primaryStart)
                    .onChange(of: threshold) { v in ClassSettings.detectionThreshold = v }
                Text("Higher values ensure confident detections while lower values capture more possibilities.")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var classesCard: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Classes")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)

                LazyVStack(spacing: 12) {
                    ForEach(classes, id: \.self) { label in
                        classRow(for: label)
                            .animation(.easeInOut, value: ClassSettings.classImageURLString(for: label))
                    }
                }
            }
        }
    }

    private func classRow(for label: String) -> some View {
        HStack(spacing: 14) {
            classThumbnail(label: label)
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)

            Spacer()

            Button {
                dismissKeyboard()
                pickLabelForImage = label
                isPickingImage = true
            } label: {
                Image(systemName: "photo.on.rectangle")
                    .foregroundStyle(Theme.textSecondary)
                    .padding(6)
            }

            Toggle("", isOn: Binding(get: { ClassSettings.isEnabled(label: label) }, set: { val in
                withAnimation {
                    ClassSettings.setEnabled(val, for: label)
                    selectedPreset = .custom
                    ClassSettings.selectedPreset = .custom
                }
            }))
            .labelsHidden()
            .toggleStyle(SwitchToggleStyle(tint: Theme.primaryStart))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func load() {
        classes = YOLODetector.shared.availableClassNames
        threshold = ClassSettings.detectionThreshold
    }

    @ViewBuilder
    private func classThumbnail(label: String) -> some View {
        if let ui = ClassSettings.classImage(for: label) {
            Image(uiImage: ui)
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

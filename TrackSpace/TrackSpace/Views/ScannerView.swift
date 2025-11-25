import SwiftUI
import AVFoundation
import PhotosUI
import Combine
import UIKit
import CoreData

// Dedicated view keeps preview layer sized correctly as layout changes.
final class CameraPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        view.previewLayer.videoGravity = .resizeAspectFill
        view.previewLayer.session = session
        return view
    }
    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        if uiView.previewLayer.session !== session {
            uiView.previewLayer.session = session
        }
    }
}

final class CameraManager: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var captureHandler: ((UIImage?) -> Void)?
    @Published var isTorchOn = false

    func configure() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            setupSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted { self.setupSession() }
            }
        default:
            break
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else { session.commitConfiguration(); return }
        if session.canAddInput(input) { session.addInput(input) }
        if session.canAddOutput(output) { session.addOutput(output) }
        session.commitConfiguration()
        DispatchQueue.global(qos: .userInitiated).async {
            self.session.startRunning()
        }
    }

    func toggleTorch() {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            device.torchMode = isTorchOn ? .off : .on
            isTorchOn.toggle()
            device.unlockForConfiguration()
        } catch { }
    }

    func capturePhoto(_ handler: @escaping (UIImage?) -> Void) {
        captureHandler = handler
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let data = photo.fileDataRepresentation(), let img = UIImage(data: data) {
            captureHandler?(img)
        } else {
            captureHandler?(nil)
        }
        captureHandler = nil
    }
}

struct PhotoPickerView: UIViewControllerRepresentable {
    var completion: (UIImage?) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
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
                first.itemProvider.loadObject(ofClass: UIImage.self) { obj, _ in
                    DispatchQueue.main.async { self.completion(obj as? UIImage) }
                }
            } else { completion(nil) }
        }
    }
}

struct ScannerView: View {
    @StateObject private var camera = CameraManager()
    @State private var isPresentingPicker = false
    @State private var saveMessage: String = ""
    @State private var showSavedBanner = false
    
    @State private var isPresentingReview = false
    @State private var reviewImage: UIImage? = nil
    @State private var reviewDetections: [Detection] = []
    @State private var capturePulse = false
    @State private var neonDrift = false
    
    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.35), Color.clear, Color.black.opacity(0.55)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            decorativeBubbles

            VStack(spacing: 18) {
                topBar
                headerCard
                Spacer()
                controlPanel
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .onAppear { camera.configure() }
        .sheet(isPresented: $isPresentingPicker) {
            PhotoPickerView { image in
                guard let image else { return }
                YOLODetector.shared.detect(uiImage: image) { detections in
                    let threshold = ClassSettings.detectionThreshold
                    let enabled = Set(YOLODetector.shared.availableClassNames.filter { ClassSettings.isEnabled(label: $0) })
                    let filtered = detections.filter { Double($0.confidence) >= threshold && enabled.contains($0.label) }
                    reviewImage = image
                    reviewDetections = filtered
                    isPresentingReview = true
                }
            }
        }
        
        .sheet(isPresented: $isPresentingReview) {
            if let img = reviewImage {
                NavigationView {
                    DetectionReviewView(image: img, initialDetections: reviewDetections)
                }
                .toolbarColorScheme(.dark, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.clear, for: .navigationBar)
            } else {
                Text("No image for review")
            }
        }
    }
    // Simple location picker sheet
    
    // quickSave moved to `ScannerExtras.swift` to keep this file focused
}

private extension ScannerView {
    var enabledClassCount: Int {
        let classes = YOLODetector.shared.availableClassNames
        return classes.filter { ClassSettings.isEnabled(label: $0) }.count
    }

    var headerCard: some View {
        ScannerCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Ready to Scan")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.white)

                HStack(spacing: 12) {
                    pill(text: "\(enabledClassCount) classes", icon: "square.stack.3d.up.fill")
                    pill(text: String(format: "%.0f%% threshold", ClassSettings.detectionThreshold * 100), icon: "target")
                }

                Divider().background(Color.white.opacity(0.1))

                Text("Align the object in frame, then tap the capture button. Importing from your gallery also works great.")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.8))
            }
        }
    }

    var controlPanel: some View {
        ScannerCard {
            VStack(spacing: 18) {
                HStack(spacing: 16) {
                    quickActionButton(title: "Library", icon: "photo.on.rectangle") {
                        dismissKeyboard()
                        isPresentingPicker = true
                    }
                    quickActionButton(title: camera.isTorchOn ? "Torch On" : "Torch Off", icon: camera.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill") {
                        camera.toggleTorch()
                    }
                }

                captureButton

                Text("Tap capture • Hold steady • Review detections before saving")
                    .font(.caption)
                    .foregroundStyle(Color.white.opacity(0.75))
            }
        }
    }

    func quickActionButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(gradient: Gradient(colors: [Color.white.opacity(0.25), Color.white.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    var captureButton: some View {
        Button {
            capture()
        } label: {
            ZStack {
                Circle()
                    .strokeBorder(Theme.cardStroke, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .scaleEffect(capturePulse ? 1.1 : 0.9)
                    .opacity(0.5)
                Circle()
                    .fill(LinearGradient(gradient: Gradient(colors: [Theme.primaryStart, Theme.primaryEnd]), startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 92, height: 92)
                    .shadow(color: Theme.primaryStart.opacity(0.6), radius: 20, x: 0, y: 12)
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                capturePulse = true
            }
        }
    }

    var topBar: some View {
        HStack {
            Label("Live Vision", systemImage: "dot.scope")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.18))
                .clipShape(Capsule())

            Spacer()

            pill(text: "Auto", icon: "wand.and.stars")
        }
    }

    func pill(text: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption.bold())
        .foregroundStyle(Color.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.2))
        .clipShape(Capsule())
    }

    var decorativeBubbles: some View {
        ZStack {
            Circle()
                .fill(Theme.headerGradient)
                .blur(radius: 160)
                .opacity(0.35)
                .frame(width: 420, height: 420)
                .offset(x: neonDrift ? -130 : -190, y: neonDrift ? -250 : -190)

            Circle()
                .stroke(Theme.cardStroke)
                .frame(width: 260, height: 260)
                .blur(radius: 8)
                .offset(x: neonDrift ? 150 : 90, y: neonDrift ? 280 : 240)
                .opacity(0.4)

            RoundedRectangle(cornerRadius: 120, style: .continuous)
                .fill(Theme.accentGradient.opacity(0.25))
                .blur(radius: 90)
                .frame(width: 300, height: 220)
                .offset(x: neonDrift ? 200 : 150, y: neonDrift ? -40 : -80)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 4).repeatForever(autoreverses: true)) {
                neonDrift.toggle()
            }
        }
    }

    func capture() {
        camera.capturePhoto { image in
            guard let image else { return }
            YOLODetector.shared.detect(uiImage: image) { detections in
                let threshold = ClassSettings.detectionThreshold
                let enabled = Set(YOLODetector.shared.availableClassNames.filter { ClassSettings.isEnabled(label: $0) })
                let filtered = detections.filter { Double($0.confidence) >= threshold && enabled.contains($0.label) }
                reviewImage = image
                reviewDetections = filtered
                dismissKeyboard()
                isPresentingReview = true
            }
        }
    }
}

private struct ScannerCard<Content: View>: View {
    var content: () -> Content
    var body: some View {
        content()
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 14)
    }
}

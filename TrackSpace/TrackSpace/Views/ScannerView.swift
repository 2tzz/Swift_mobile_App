import SwiftUI
import AVFoundation
import PhotosUI
import Combine
import UIKit
import CoreData

// Camera preview layer for SwiftUI (file-scoped helper)
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        view.layer.addSublayer(layer)
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.layer.sublayers?.forEach { sub in
            if let preview = sub as? AVCaptureVideoPreviewLayer {
                preview.frame = uiView.bounds
            }
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
    
    var body: some View {
        ZStack {
            CameraPreview(session: camera.session)
                .ignoresSafeArea()
            VStack {
                Spacer()
                
                HStack {
                    Button {
                        // dismiss keyboard (if any) before presenting photo picker
                        dismissKeyboard()
                        isPresentingPicker = true
                    } label: {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 22, weight: .medium))
                            .padding(12)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    Button {
                        camera.capturePhoto { image in
                            guard let image else { return }
                            YOLODetector.shared.detect(uiImage: image) { detections in
                                let threshold = ClassSettings.detectionThreshold
                                let enabled = Set(YOLODetector.shared.availableClassNames.filter { ClassSettings.isEnabled(label: $0) })
                                let filtered = detections.filter { Double($0.confidence) >= threshold && enabled.contains($0.label) }
                                reviewImage = image
                                reviewDetections = filtered
                                // ensure keyboard hidden before presenting review
                                dismissKeyboard()
                                isPresentingReview = true
                            }
                        }
                    } label: {
                        ZStack {
                            Circle().fill(.white.opacity(0.2)).frame(width: 74, height: 74)
                            Circle().fill(.white).frame(width: 60, height: 60)
                        }
                    }
                    Spacer()
                    Button {
                        camera.toggleTorch()
                    } label: {
                        Image(systemName: camera.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                            .font(.system(size: 22, weight: .medium))
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
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
            } else {
                Text("No image for review")
            }
        }
    }
    // Simple location picker sheet
    
    // quickSave moved to `ScannerExtras.swift` to keep this file focused
}

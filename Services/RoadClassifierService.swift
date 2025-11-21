import Foundation
import CoreML
import Vision
import UIKit

/// Service responsible for running the road issue CoreML model using Vision.
/// Drop your `RoadIssueDetector.mlmodel` into the Xcode project; this service
/// will attempt to load it by name and fall back to a mock classification if
/// the model is missing or fails to load.
final class RoadClassifierService {
    static let shared = RoadClassifierService()

    private var coreMLModel: VNCoreMLModel?

    private init() {
        loadModelIfAvailable()
    }

    private func loadModelIfAvailable() {
        // IMPORTANT: When you add RoadIssueDetector.mlmodel to the project,
        // Xcode will generate a `RoadIssueDetector` class. Replace the `if let`
        // below with the actual generated model type if the name differs.
        do {
            if let modelURL = Bundle.main.url(forResource: "RoadIssueDetector", withExtension: "mlmodelc") {
                let compiledURL = modelURL
                let mlModel = try MLModel(contentsOf: compiledURL)
                coreMLModel = try VNCoreMLModel(for: mlModel)
            } else if let compiledURL = try? MLModel.compileModel(at: Bundle.main.url(forResource: "RoadIssueDetector", withExtension: "mlmodel")!) {
                let mlModel = try MLModel(contentsOf: compiledURL)
                coreMLModel = try VNCoreMLModel(for: mlModel)
            }
        } catch {
            // If the model is not present yet or fails to load, we keep
            // `coreMLModel` as nil and rely on a mock classification.
            coreMLModel = nil
        }
    }

    struct ClassificationResult {
        let label: String
        let confidence: Double
    }

    /// Public async API to classify a UIImage. If the underlying model is not
    /// available, this returns a mock `Pothole` classification so that the UI
    /// can be developed and tested without the real model.
    func classify(image: UIImage) async -> ClassificationResult {
        guard let coreMLModel = coreMLModel else {
            // Mock result used when model is missing
            return ClassificationResult(label: "Pothole", confidence: 0.9)
        }

        return await withCheckedContinuation { continuation in
            let request = VNCoreMLRequest(model: coreMLModel) { request, _ in
                if let results = request.results as? [VNClassificationObservation],
                   let best = results.first {
                    let result = ClassificationResult(
                        label: best.identifier,
                        confidence: Double(best.confidence)
                    )
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(returning: ClassificationResult(label: "Unknown", confidence: 0.0))
                }
            }

            guard let cgImage = image.cgImage else {
                continuation.resume(returning: ClassificationResult(label: "InvalidImage", confidence: 0.0))
                return
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: ClassificationResult(label: "Error", confidence: 0.0))
                }
            }
        }
    }
}

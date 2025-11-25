import Foundation
import Vision
import CoreImage
import UIKit
import CoreML

final class YOLODetector {
    static let shared = YOLODetector()
    private let queue = DispatchQueue(label: "yolo.detector.queue")

    private func debugListBundleModels() {
        let exts = ["mlpackage", "mlmodelc", "mlmodel"]
        var found: [String] = []
        if let resourceURL = Bundle.main.resourceURL {
            let fm = FileManager.default
            if let enumerator = fm.enumerator(at: resourceURL, includingPropertiesForKeys: nil) {
                for case let url as URL in enumerator {
                    if exts.contains(url.pathExtension) {
                        found.append(url.path)
                    }
                }
            }
        }
        print("[YOLODetector] Bundle resource search results (recursive): \(found)")
        for ext in exts {
            if let urls = Bundle.main.urls(forResourcesWithExtension: ext, subdirectory: nil) {
                print("[YOLODetector] top-level urls for extension \(ext): \(urls)")
            } else {
                print("[YOLODetector] no top-level urls for extension \(ext)")
            }
        }
    }

    private lazy var vnModel: VNCoreMLModel? = {
        // Print bundle model resources to help debug missing model in runtime bundle
        debugListBundleModels()
        // Robust model discovery: try compiled .mlmodelc, packaged .mlpackage, or raw .mlmodel (compile at runtime)
        func tryLoadModel(at url: URL) -> VNCoreMLModel? {
            print("[YOLODetector] Attempting to load model at: \(url)")
            if let compiled = try? MLModel(contentsOf: url) {
                if let vn = try? VNCoreMLModel(for: compiled) {
                    return vn
                } else {
                    print("[YOLODetector] Failed to create VNCoreMLModel for compiled model")
                }
            } else {
                print("[YOLODetector] MLModel(contentsOf:) failed for url: \(url)")
            }
            return nil
        }

        // Try a few likely resource base names (projects sometimes drop the 'v')
        let candidateNames = ["yolov11n", "yolo11n"]
        for name in candidateNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                if let vn = tryLoadModel(at: url) { return vn }
            }
        }

        // 2) packaged model (.mlpackage) -> look for Data/com.apple.CoreML/model.mlmodelc or model.mlmodel
        for name in candidateNames {
            if let pkg = Bundle.main.url(forResource: name, withExtension: "mlpackage") {
                let dataCoreML = pkg.appendingPathComponent("Data/com.apple.CoreML")
                let compiled = dataCoreML.appendingPathComponent("model.mlmodelc")
                let raw = dataCoreML.appendingPathComponent("model.mlmodel")
                if FileManager.default.fileExists(atPath: compiled.path) {
                    if let vn = tryLoadModel(at: compiled) { return vn }
                }
                if FileManager.default.fileExists(atPath: raw.path) {
                    // compile raw model at runtime into temp compiled url
                    do {
                        let compiledURL = try MLModel.compileModel(at: raw)
                        if let vn = tryLoadModel(at: compiledURL) { return vn }
                    } catch {
                        print("[YOLODetector] Failed to compile model.mlmodel: \(error)")
                    }
                }
            }
        }

        // 3) try any .mlmodel in bundle resources
        if let rawURL = Bundle.main.urls(forResourcesWithExtension: "mlmodel", subdirectory: nil)?.first {
            do {
                let compiledURL = try MLModel.compileModel(at: rawURL)
                if let vn = tryLoadModel(at: compiledURL) { return vn }
            } catch {
                print("[YOLODetector] Fallback compile error: \(error)")
            }
        }

        print("[YOLODetector] No model could be loaded from bundle")
        return nil
    }()

    private lazy var coreMLModel: MLModel? = {
        // Try same discovery strategy as vnModel but return raw MLModel
        let candidateNames = ["yolov11n", "yolo11n"]
        for name in candidateNames {
            if let url = Bundle.main.url(forResource: name, withExtension: "mlmodelc") {
                if let m = try? MLModel(contentsOf: url) { return m }
            }
        }
        for name in candidateNames {
            if let pkg = Bundle.main.url(forResource: name, withExtension: "mlpackage") {
                let dataCoreML = pkg.appendingPathComponent("Data/com.apple.CoreML")
                let compiled = dataCoreML.appendingPathComponent("model.mlmodelc")
                let raw = dataCoreML.appendingPathComponent("model.mlmodel")
                if FileManager.default.fileExists(atPath: compiled.path) {
                    if let m = try? MLModel(contentsOf: compiled) { return m }
                }
                if FileManager.default.fileExists(atPath: raw.path) {
                    if let compiledURL = try? MLModel.compileModel(at: raw), let m = try? MLModel(contentsOf: compiledURL) { return m }
                }
            }
        }
        if let raw = Bundle.main.urls(forResourcesWithExtension: "mlmodel", subdirectory: nil)?.first {
            if let compiledURL = try? MLModel.compileModel(at: raw), let m = try? MLModel(contentsOf: compiledURL) { return m }
        }
        print("[YOLODetector] coreMLModel not found in bundle")
        return nil
    }()

    // Try to read class names from model package Metadata.json (or fallback to MLModel metadata)
    private lazy var classNames: [String]? = {
        let candidateNames = ["yolov11n", "yolo11n"]
        let fm = FileManager.default
        for name in candidateNames {
            if let pkg = Bundle.main.url(forResource: name, withExtension: "mlpackage") {
                let meta = pkg.appendingPathComponent("Data/com.apple.CoreML/Metadata.json")
                if fm.fileExists(atPath: meta.path), let data = try? Data(contentsOf: meta), let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let creator = obj["MLModelCreatorDefinedKey"] as? [String: Any], let namesStr = creator["names"] as? String {
                    // namesStr format: "{0: 'person', 1: 'bicycle', ...}"
                    do {
                        let regex = try NSRegularExpression(pattern: "'([^']+)'", options: [])
                        let s = namesStr as NSString
                        let matches = regex.matches(in: namesStr, options: [], range: NSRange(location: 0, length: s.length))
                        let names = matches.compactMap { m -> String? in
                            guard m.numberOfRanges > 1 else { return nil }
                            return s.substring(with: m.range(at: 1))
                        }
                        if !names.isEmpty { return names }
                    } catch {
                        // ignore
                    }
                }
            }
        }

        // Fallback: try MLModel's metadata if available
        if let model = coreMLModel {
            let md = model.modelDescription.metadata[.creatorDefinedKey] as? [String: Any]
            if let namesStr = md?["names"] as? String {
                do {
                    let regex = try NSRegularExpression(pattern: "'([^']+)'", options: [])
                    let s = namesStr as NSString
                    let matches = regex.matches(in: namesStr, options: [], range: NSRange(location: 0, length: s.length))
                    let names = matches.compactMap { m -> String? in
                        guard m.numberOfRanges > 1 else { return nil }
                        return s.substring(with: m.range(at: 1))
                    }
                    if !names.isEmpty { return names }
                } catch { }
            }
        }

        return nil
    }()

    // Public accessor for available class names (empty array if unknown)
    public var availableClassNames: [String] {
        return classNames ?? []
    }

    func detect(uiImage: UIImage, completion: @escaping ([Detection]) -> Void) {
        // Prefer direct Core ML path first, since many YOLO packages don't expose Vision object detections
        queue.async {
            if let direct = self.predictDirect(uiImage: uiImage), !direct.isEmpty {
                DispatchQueue.main.async { completion(direct) }
                return
            }

            // Fallback to Vision if direct inference failed or returned empty
            guard let vnModel = self.vnModel else {
                print("[YOLODetector] vnModel unavailable, aborting Vision detection")
                DispatchQueue.main.async { completion([]) }
                return
            }

            // Prefer CGImage but fall back to CIImage when needed
            let cgImage: CGImage? = uiImage.cgImage
            let ciImage: CIImage? = uiImage.ciImage

            func makeRequest(option: VNImageCropAndScaleOption, done: @escaping ([Detection]) -> Void) -> VNCoreMLRequest {
                let req = VNCoreMLRequest(model: vnModel) { request, _ in
                    if let obs = request.results as? [VNRecognizedObjectObservation] {
                        print("[YOLODetector] Result type: VNRecognizedObjectObservation, count=\(obs.count), option=\(option)")
                        let detections = obs.map { o -> Detection in
                            let best = o.labels.first
                            let label = best?.identifier ?? "Object"
                            let conf = best?.confidence ?? 0
                            var r = o.boundingBox
                            r.origin.y = 1 - r.origin.y - r.size.height
                            return Detection(label: label, rect: r, confidence: conf)
                        }
                        done(detections)
                    } else if let feats = request.results as? [VNCoreMLFeatureValueObservation] {
                        print("[YOLODetector] Result type: VNCoreMLFeatureValueObservation, count=\(feats.count), option=\(option)")
                        done([])
                    } else {
                        print("[YOLODetector] Unknown result type: \(String(describing: request.results?.first)), option=\(option)")
                        done([])
                    }
                }
                req.imageCropAndScaleOption = option
                return req
            }

            let handler: VNImageRequestHandler
            if let cg = cgImage {
                handler = VNImageRequestHandler(cgImage: cg, orientation: uiImage.cgImageOrientation, options: [:])
            } else if let ci = ciImage {
                handler = VNImageRequestHandler(ciImage: ci, orientation: uiImage.cgImageOrientation, options: [:])
            } else {
                print("[YOLODetector] No cgImage or ciImage available for VNImageRequestHandler")
                DispatchQueue.main.async { completion([]) }
                return
            }
            do {
                var final: [Detection] = []
                try handler.perform([makeRequest(option: .scaleFit) { final = $0 }])
                if final.isEmpty {
                    try handler.perform([makeRequest(option: .scaleFill) { final = $0 }])
                }
                DispatchQueue.main.async { completion(final) }
            } catch {
                print("[YOLODetector] Request error: \(error)")
                DispatchQueue.main.async { completion([]) }
            }
        }
    }

    // MARK: - Direct Core ML path
    private func predictDirect(uiImage: UIImage) -> [Detection]? {
        guard let model = coreMLModel else { return nil }

        // Determine input name and image size (prefer 'image')
        let inputs = model.modelDescription.inputDescriptionsByName
        guard let inputDesc = inputs["image"] ?? inputs.first?.value else { return nil }
        let inputName = inputs["image"] != nil ? "image" : inputs.first!.key
        let imageConstraint = inputDesc.imageConstraint
        let size = CGSize(width: imageConstraint?.pixelsWide ?? 640, height: imageConstraint?.pixelsHigh ?? 640)

        guard let pixelBuffer = uiImage.resizedPixelBuffer(to: size) else { return nil }

        // Build input feature dictionary, including optional thresholds if supported
        var features: [String: MLFeatureValue] = [:]
        features[inputName] = MLFeatureValue(pixelBuffer: pixelBuffer)
        let inputNames = Set(model.modelDescription.inputDescriptionsByName.keys)
        if inputNames.contains("confidenceThreshold") {
            features["confidenceThreshold"] = MLFeatureValue(double: 0.05)
        }
        if inputNames.contains("iouThreshold") {
            features["iouThreshold"] = MLFeatureValue(double: 0.45)
        }

        let provider = try? MLDictionaryFeatureProvider(dictionary: features)
        guard let provider else { return nil }

        guard let out = try? model.prediction(from: provider) else { return nil }

        // Discover outputs
        let names = Array(out.featureNames)
        print("[YOLODetector] Output feature names: \(names)")

        func feature(_ name: String) -> MLMultiArray? {
            return out.featureValue(for: name)?.multiArrayValue
        }

        // Try common names first (per your model's Predictions: 'confidence' [D,80], 'coordinates' [D,4])
        var coords: MLMultiArray? = feature("coordinates") ?? feature("boxes")
        var conf: MLMultiArray? = feature("confidence") ?? feature("scores")
        _ = feature("labels") ?? feature("classes")

        // If unknown names, heuristic: pick any [D,4] for coords, and any [D] or [D,C] for conf
        if coords == nil || conf == nil {
            for n in names {
                guard let arr = feature(n) else { continue }
                if arr.shape.count == 2, arr.shape.last?.intValue == 4 { coords = coords ?? arr }
                if arr.shape.count == 1 { conf = conf ?? arr }
                if arr.shape.count == 2, (arr.shape.last?.intValue ?? 0) > 4 { conf = conf ?? arr }
            }
        }

        guard let coordsArr = coords else { print("[YOLODetector] No coordinates output found"); return [] }

        // Decode
        let coordsShape = coordsArr.shape.map { $0.intValue }
        let d = coordsShape.first ?? 0
        var results: [Detection] = []

        // Helper to read MLMultiArray using strides (supports float32/double)
        func linearIndex(_ a: MLMultiArray, _ indices: [Int]) -> Int {
            let strides = a.strides.map { $0.intValue }
            var offset = 0
            for k in 0..<indices.count { offset += indices[k] * strides[k] }
            return offset
        }
        func readElement(_ a: MLMultiArray, _ offset: Int) -> Double {
            switch a.dataType {
            case .double:
                let ptr = a.dataPointer.bindMemory(to: Double.self, capacity: a.count)
                return ptr[offset]
            case .float32:
                let ptr = a.dataPointer.bindMemory(to: Float32.self, capacity: a.count)
                return Double(ptr[offset])
            case .float16:
                // Minimal float16 support: return 0 (rarely used in NMS outputs)
                return 0
            default:
                return 0
            }
        }
        func value(_ a: MLMultiArray, _ i: Int, _ j: Int) -> Double { readElement(a, linearIndex(a, [i, j])) }
        func value1D(_ a: MLMultiArray, _ i: Int) -> Double { readElement(a, linearIndex(a, [i])) }

        let confShape = conf?.shape.map { $0.intValue } ?? []
        let hasPerClass = confShape.count == 2

        // Inspect first row for format hints
        if d > 0 {
            let cx0 = value(coordsArr, 0, 0)
            let cy0 = value(coordsArr, 0, 1)
            let w0  = value(coordsArr, 0, 2)
            let h0  = value(coordsArr, 0, 3)
            print("[YOLODetector] coords[0]: \(cx0), \(cy0), \(w0), \(h0)  shape=\(coordsShape)")
            if let confArr = conf {
                if hasPerClass { print("[YOLODetector] conf shape: \(confShape) sample=\(value(confArr,0,0))") }
                else { print("[YOLODetector] conf shape: \(confShape) sample=\(value1D(confArr,0))") }
            }
        }

        for i in 0..<d {
            let a0 = value(coordsArr, i, 0)
            let a1 = value(coordsArr, i, 1)
            let a2 = value(coordsArr, i, 2)
            let a3 = value(coordsArr, i, 3)
            var score: Double = 0
            var clsIdx: Int = -1
            if let confArr = conf {
                if hasPerClass {
                    let classes = confShape.last ?? 0
                    var best = -Double.infinity
                    var bestIdx = 0
                    for c in 0..<classes {
                        let v = value(confArr, i, c)
                        if v > best { best = v; bestIdx = c }
                    }
                    score = best
                    clsIdx = bestIdx
                } else {
                    score = value1D(confArr, i)
                }
            } else {
                score = 1.0
            }
            // simple score filter
            if score < 0.01 { continue }

            // Try to interpret coordinates:
            // 1) xywh normalized
            var rects: [CGRect] = []
            do {
                let cx = a0, cy = a1, w = a2, h = a3
                let x = cx - w/2
                let y = cy - h/2
                rects.append(CGRect(x: x, y: y, width: w, height: h))
            }
            // 2) xyxy normalized
            do {
                let x1 = a0, y1 = a1, x2 = a2, y2 = a3
                let w = x2 - x1
                let h = y2 - y1
                rects.append(CGRect(x: x1, y: y1, width: w, height: h))
            }
            // 3) xyxy absolute to input size (assume 640)
            do {
                let x1 = a0/640.0, y1 = a1/640.0, x2 = a2/640.0, y2 = a3/640.0
                rects.append(CGRect(x: x1, y: y1, width: x2 - x1, height: y2 - y1))
            }

            // Keep first rect that is plausible within [0,1]
            var picked: CGRect? = nil
            for r in rects {
                if r.width.isFinite && r.height.isFinite && r.width > 0 && r.height > 0 {
                    let rx = max(0, min(1, r.origin.x))
                    let ry = max(0, min(1, r.origin.y))
                    let rw = max(0, min(1 - rx, r.size.width))
                    let rh = max(0, min(1 - ry, r.size.height))
                    if rw > 0.005 && rh > 0.005 { picked = CGRect(x: rx, y: ry, width: rw, height: rh); break }
                }
            }
            guard let rect = picked else { continue }
            var label = clsIdx >= 0 ? "class_\(clsIdx)" : "Object"
            if let names = self.classNames, clsIdx >= 0, clsIdx < names.count {
                label = names[clsIdx]
            }
            results.append(Detection(label: label, rect: rect, confidence: Float(score)))
        }

        print("[YOLODetector] Direct detections: \(results.count)")
        return results
    }
}

private extension UIImage {
    var cgImageOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    func resizedPixelBuffer(to size: CGSize) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let width = Int(size.width)
        let height = Int(size.height)
        guard CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs, &pixelBuffer) == kCVReturnSuccess, let pb = pixelBuffer else { return nil }

        CVPixelBufferLockBaseAddress(pb, [])
        defer { CVPixelBufferUnlockBaseAddress(pb, []) }

        guard let context = CGContext(data: CVPixelBufferGetBaseAddress(pb), width: width, height: height, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pb), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue) else { return nil }
        context.clear(CGRect(x: 0, y: 0, width: width, height: height))
        // ScaleFit letterboxing
        let imageAspect = self.size.width / self.size.height
        let targetAspect = size.width / size.height
        var drawRect = CGRect(origin: .zero, size: size)
        if imageAspect > targetAspect {
            let h = size.width / imageAspect
            drawRect = CGRect(x: 0, y: (size.height - h)/2, width: size.width, height: h)
        } else {
            let w = size.height * imageAspect
            drawRect = CGRect(x: (size.width - w)/2, y: 0, width: w, height: size.height)
        }
        if let cg = self.cgImage { context.draw(cg, in: drawRect) }
        return pb
    }
}

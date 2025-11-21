import Foundation
import UIKit
import CoreLocation

@MainActor
final class SubmissionViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var issueType: String = ""
    @Published var department: String = ""
    @Published var descriptionText: String = ""
    @Published var isClassifying: Bool = false

    @Published var coordinate: CLLocationCoordinate2D?

    private let classifier: RoadClassifierService

    init(classifier: RoadClassifierService = .shared, initialCoordinate: CLLocationCoordinate2D?) {
        self.classifier = classifier
        self.coordinate = initialCoordinate
    }

    func assignCapturedImage(_ image: UIImage) {
        capturedImage = image
    }

    func classifyCurrentImage() async {
        guard let image = capturedImage else { return }
        isClassifying = true
        let result = await classifier.classify(image: image)
        isClassifying = false

        issueType = result.label
        department = departmentForIssueType(result.label)
    }

    private func departmentForIssueType(_ type: String) -> String {
        let normalized = type.lowercased()

        if normalized.contains("pothole") || normalized.contains("road") {
            return "Road Safety Dept"
        } else if normalized.contains("parking") {
            return "Traffic & Parking Dept"
        } else if normalized.contains("light") || normalized.contains("lamp") {
            return "Electrical Dept"
        } else if normalized.contains("trash") || normalized.contains("litter") || normalized.contains("garbage") {
            return "Sanitation Dept"
        } else if normalized.contains("vandal") || normalized.contains("graffiti") {
            return "Public Property Dept"
        } else {
            return "General City Services"
        }
    }
}

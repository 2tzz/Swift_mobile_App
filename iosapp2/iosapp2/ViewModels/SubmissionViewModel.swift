import Foundation
import UIKit
import CoreLocation
import Combine

@MainActor
final class SubmissionViewModel: ObservableObject {
    @Published var capturedImage: UIImage?
    @Published var issueType: String = ""
    @Published var department: String = ""
    @Published var descriptionText: String = ""
    @Published var isClassifying: Bool = false

    @Published var coordinate: CLLocationCoordinate2D?

    private let classifier: RoadClassifierService
    private let repository: ReportRepository

    init(
        classifier: RoadClassifierService = .shared,
        repository: ReportRepository = FirestoreReportRepository(),
        initialCoordinate: CLLocationCoordinate2D?
    ) {
        self.classifier = classifier
        self.repository = repository
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

    func submitReport() async throws {
        let report = Report(
            issueType: issueType.isEmpty ? "Road Issue" : issueType,
            department: department.isEmpty ? "General City Services" : department,
            descriptionText: descriptionText,
            coordinate: coordinate,
            status: .pending
        )

        try await repository.save(report: report)
    }

    private func departmentForIssueType(_ type: String) -> String {
        let normalized = type.lowercased()

        if normalized.contains("damaged road") {
            return "Road Maintenance Dept"
        } else if normalized.contains("pothole") {
            return "Road Maintenance Dept"
        } else if normalized.contains("illegal parking") || normalized.contains("parking") {
            return "Traffic & Parking Dept"
        } else if normalized.contains("broken road sign") || normalized.contains("sign") {
            return "Traffic & Signage Dept"
        } else if normalized.contains("fallen tree") || normalized.contains("fallen trees") || normalized.contains("tree") {
            return "Parks & Forestry Dept"
        } else if normalized.contains("litter") || normalized.contains("garbage") || normalized.contains("trash") || normalized.contains("public places") {
            return "Sanitation Dept"
        } else if normalized.contains("vandal") || normalized.contains("graffiti") {
            return "Public Property Dept"
        } else if normalized.contains("dead animal") {
            return "Sanitation Dept"
        } else if normalized.contains("damaged concrete") || normalized.contains("concrete structures") || normalized.contains("structure") {
            return "Public Works Dept"
        } else if normalized.contains("electric wires") || normalized.contains("electric poles") || normalized.contains("electric") || normalized.contains("wire") || normalized.contains("pole") {
            return "Electrical Dept"
        } else {
            return "General City Services"
        }
    }
}

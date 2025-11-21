import Foundation
import CoreLocation

struct Report: Identifiable, Hashable {
    enum Status: String {
        case pending
        case inProgress
        case fixed
    }

    let id: UUID
    var createdAt: Date
    var issueType: String
    var department: String
    var descriptionText: String
    var coordinate: CLLocationCoordinate2D?
    var status: Status

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        issueType: String,
        department: String,
        descriptionText: String,
        coordinate: CLLocationCoordinate2D?,
        status: Status = .pending
    ) {
        self.id = id
        self.createdAt = createdAt
        self.issueType = issueType
        self.department = department
        self.descriptionText = descriptionText
        self.coordinate = coordinate
        self.status = status
    }
}

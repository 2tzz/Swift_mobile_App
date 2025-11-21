import Foundation
import CoreData
import CoreLocation

protocol ReportRepository {
    func save(report: Report) async throws
    func fetchMyReports() async throws -> [Report]
}

final class CoreDataReportRepository: ReportRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func save(report: Report) async throws {
        try await context.perform {
            let entity = ReportEntity(context: self.context)
            entity.id = report.id
            entity.createdAt = report.createdAt
            entity.issueType = report.issueType
            entity.department = report.department
            entity.descriptionText = report.descriptionText
            entity.status = report.status.rawValue

            if let coord = report.coordinate {
                entity.latitude = NSNumber(value: coord.latitude)
                entity.longitude = NSNumber(value: coord.longitude)
            }

            if self.context.hasChanges {
                try self.context.save()
            }
        }
    }

    func fetchMyReports() async throws -> [Report] {
        try await context.perform {
            let request: NSFetchRequest<ReportEntity> = ReportEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let results = try self.context.fetch(request)

            return results.map { entity in
                let coordinate: CLLocationCoordinate2D?
                if let lat = entity.latitude?.doubleValue,
                   let lon = entity.longitude?.doubleValue {
                    coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                } else {
                    coordinate = nil
                }

                return Report(
                    id: entity.id,
                    createdAt: entity.createdAt,
                    issueType: entity.issueType,
                    department: entity.department,
                    descriptionText: entity.descriptionText ?? "",
                    coordinate: coordinate,
                    status: Report.Status(rawValue: entity.status) ?? .pending
                )
            }
        }
    }
}

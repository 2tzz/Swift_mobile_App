import Foundation
import CoreData

@objc(ReportEntity)
final class ReportEntity: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var createdAt: Date
    @NSManaged var issueType: String
    @NSManaged var department: String
    @NSManaged var descriptionText: String?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var status: String
}

extension ReportEntity {
    @nonobjc class func fetchRequest() -> NSFetchRequest<ReportEntity> {
        NSFetchRequest<ReportEntity>(entityName: "ReportEntity")
    }
}

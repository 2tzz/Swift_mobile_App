import Foundation
import CoreData

// Programmatic Core Data stack for AssetScan domain to avoid changing existing .xcdatamodeld
// Entities (programmatic):
// - InventoryItem: id(UUID), label(String), x(Double), y(Double), width(Double), height(Double), imageURL(String), location(String), date(Date)

final class AssetScanStore {
    static let shared = AssetScanStore()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "AssetScan", managedObjectModel: model)
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error: \(error)")
            }
        }
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // InventoryItem entity
        let entity = NSEntityDescription()
        entity.name = "InventoryItem"
        entity.managedObjectClassName = NSStringFromClass(InventoryItem.self)

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false

        let labelAttr = NSAttributeDescription()
        labelAttr.name = "label"
        labelAttr.attributeType = .stringAttributeType
        labelAttr.isOptional = false

        let xAttr = NSAttributeDescription()
        xAttr.name = "x"
        xAttr.attributeType = .doubleAttributeType
        xAttr.isOptional = false

        let yAttr = NSAttributeDescription()
        yAttr.name = "y"
        yAttr.attributeType = .doubleAttributeType
        yAttr.isOptional = false

        let wAttr = NSAttributeDescription()
        wAttr.name = "width"
        wAttr.attributeType = .doubleAttributeType
        wAttr.isOptional = false

        let hAttr = NSAttributeDescription()
        hAttr.name = "height"
        hAttr.attributeType = .doubleAttributeType
        hAttr.isOptional = false

        let imageURLAttr = NSAttributeDescription()
        imageURLAttr.name = "imageURL"
        imageURLAttr.attributeType = .stringAttributeType
        imageURLAttr.isOptional = false

        let locationAttr = NSAttributeDescription()
        locationAttr.name = "location"
        locationAttr.attributeType = .stringAttributeType
        locationAttr.isOptional = false

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false

        entity.properties = [idAttr, labelAttr, xAttr, yAttr, wAttr, hAttr, imageURLAttr, locationAttr, dateAttr]

        model.entities = [entity]
        return model
    }
}

@objc(InventoryItem)
public class InventoryItem: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var label: String
    @NSManaged public var x: Double
    @NSManaged public var y: Double
    @NSManaged public var width: Double
    @NSManaged public var height: Double
    @NSManaged public var imageURL: String
    @NSManaged public var location: String
    @NSManaged public var date: Date
}

extension InventoryItem {
    @nonobjc public class func fetchRequestAll() -> NSFetchRequest<InventoryItem> {
        let req = NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return req
    }
}

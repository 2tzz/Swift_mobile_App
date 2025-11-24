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
        // Configure persistent store descriptions with automatic lightweight migration
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        } else {
            // Put sqlite store in Application Support for stability
            let fm = FileManager.default
            let appSupport = try? fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            let dir = appSupport ?? fm.urls(for: .documentDirectory, in: .userDomainMask).first!
            let storeURL = dir.appendingPathComponent("AssetScan.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            // Enable lightweight migration options
            description.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
            description.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
            container.persistentStoreDescriptions = [description]
        }

        // Try to load stores; on failure attempt to remove existing store files and retry once (development fallback)
        var loadError: Error?
        container.loadPersistentStores { desc, error in
            if let error = error {
                loadError = error
            }
        }

        if let err = loadError {
            // If loading failed, attempt to remove sqlite store files and retry (helps during dev when model changed)
            if !inMemory, let desc = container.persistentStoreDescriptions.first, let url = desc.url {
                let fm = FileManager.default
                let shm = url.appendingPathExtension("-shm")
                let wal = url.appendingPathExtension("-wal")
                do {
                    if fm.fileExists(atPath: url.path) { try fm.removeItem(at: url) }
                    if fm.fileExists(atPath: shm.path) { try fm.removeItem(at: shm) }
                    if fm.fileExists(atPath: wal.path) { try fm.removeItem(at: wal) }
                    // Retry
                    var retryError: Error?
                    container.loadPersistentStores { _, error in retryError = error }
                    if let retryError = retryError {
                        fatalError("Unresolved error after removing store files: \(retryError)")
                    }
                } catch {
                    fatalError("Unresolved error cleaning old store: \(error)")
                }
            } else {
                fatalError("Unresolved error: \(err)")
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

        let countAttr = NSAttributeDescription()
        countAttr.name = "count"
        countAttr.attributeType = .integer64AttributeType
        countAttr.isOptional = false

        let locationAttr = NSAttributeDescription()
        locationAttr.name = "location"
        locationAttr.attributeType = .stringAttributeType
        locationAttr.isOptional = false

        let dateAttr = NSAttributeDescription()
        dateAttr.name = "date"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = false

        entity.properties = [idAttr, labelAttr, xAttr, yAttr, wAttr, hAttr, imageURLAttr, locationAttr, dateAttr, countAttr]

        // Room entity
        let roomEntity = NSEntityDescription()
        roomEntity.name = "Room"
        roomEntity.managedObjectClassName = NSStringFromClass(Room.self)

        let roomId = NSAttributeDescription()
        roomId.name = "id"
        roomId.attributeType = .UUIDAttributeType
        roomId.isOptional = false

        let roomName = NSAttributeDescription()
        roomName.name = "name"
        roomName.attributeType = .stringAttributeType
        roomName.isOptional = false

        let roomDate = NSAttributeDescription()
        roomDate.name = "date"
        roomDate.attributeType = .dateAttributeType
        roomDate.isOptional = false

        // relationships
        let roomToItems = NSRelationshipDescription()
        roomToItems.name = "items"
        roomToItems.destinationEntity = entity
        roomToItems.minCount = 0
        roomToItems.maxCount = 0 // to-many
        roomToItems.deleteRule = .cascadeDeleteRule

        let itemToRoom = NSRelationshipDescription()
        itemToRoom.name = "room"
        itemToRoom.destinationEntity = roomEntity
        itemToRoom.minCount = 0
        itemToRoom.maxCount = 1
        itemToRoom.deleteRule = .nullifyDeleteRule

        // set inverses
        roomToItems.inverseRelationship = itemToRoom
        itemToRoom.inverseRelationship = roomToItems

        roomEntity.properties = [roomId, roomName, roomDate, roomToItems]

        // add inverse relationship to InventoryItem properties
        entity.properties.append(itemToRoom)

        model.entities = [entity, roomEntity]
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
    @NSManaged public var count: Int64
    @NSManaged public var room: Room?
}

@objc(Room)
public class Room: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var date: Date
    @NSManaged public var items: Set<InventoryItem>
}

extension InventoryItem {
    @nonobjc public class func fetchRequestAll() -> NSFetchRequest<InventoryItem> {
        let req = NSFetchRequest<InventoryItem>(entityName: "InventoryItem")
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        return req
    }
}

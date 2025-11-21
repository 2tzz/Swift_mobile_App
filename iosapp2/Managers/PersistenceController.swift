import Foundation
import CoreData

/// Lightweight Core Data stack created programmatically so we don't rely on
/// an .xcdatamodel file. If you prefer, you can later replace this with a
/// standard Xcode data model and keep the same entity/attribute names.
final class PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private init(inMemory: Bool = false) {
        let model = Self.makeModel()
        container = NSPersistentContainer(name: "FixLKDataModel", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error loading Core Data store: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    private static func makeModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let reportEntity = NSEntityDescription()
        reportEntity.name = "ReportEntity"
        reportEntity.managedObjectClassName = "ReportEntity"

        var properties: [NSAttributeDescription] = []

        let idAttr = NSAttributeDescription()
        idAttr.name = "id"
        idAttr.attributeType = .UUIDAttributeType
        idAttr.isOptional = false
        properties.append(idAttr)

        let createdAtAttr = NSAttributeDescription()
        createdAtAttr.name = "createdAt"
        createdAtAttr.attributeType = .dateAttributeType
        createdAtAttr.isOptional = false
        properties.append(createdAtAttr)

        let issueTypeAttr = NSAttributeDescription()
        issueTypeAttr.name = "issueType"
        issueTypeAttr.attributeType = .stringAttributeType
        issueTypeAttr.isOptional = false
        properties.append(issueTypeAttr)

        let departmentAttr = NSAttributeDescription()
        departmentAttr.name = "department"
        departmentAttr.attributeType = .stringAttributeType
        departmentAttr.isOptional = false
        properties.append(departmentAttr)

        let descriptionAttr = NSAttributeDescription()
        descriptionAttr.name = "descriptionText"
        descriptionAttr.attributeType = .stringAttributeType
        descriptionAttr.isOptional = true
        properties.append(descriptionAttr)

        let latitudeAttr = NSAttributeDescription()
        latitudeAttr.name = "latitude"
        latitudeAttr.attributeType = .doubleAttributeType
        latitudeAttr.isOptional = true
        properties.append(latitudeAttr)

        let longitudeAttr = NSAttributeDescription()
        longitudeAttr.name = "longitude"
        longitudeAttr.attributeType = .doubleAttributeType
        longitudeAttr.isOptional = true
        properties.append(longitudeAttr)

        let statusAttr = NSAttributeDescription()
        statusAttr.name = "status"
        statusAttr.attributeType = .stringAttributeType
        statusAttr.isOptional = false
        properties.append(statusAttr)

        reportEntity.properties = properties

        let userEntity = NSEntityDescription()
        userEntity.name = "UserEntity"
        userEntity.managedObjectClassName = "UserEntity"

        var userProps: [NSAttributeDescription] = []

        let userId = NSAttributeDescription()
        userId.name = "id"
        userId.attributeType = .UUIDAttributeType
        userId.isOptional = false
        userProps.append(userId)

        let userName = NSAttributeDescription()
        userName.name = "name"
        userName.attributeType = .stringAttributeType
        userName.isOptional = false
        userProps.append(userName)

        let userEmail = NSAttributeDescription()
        userEmail.name = "email"
        userEmail.attributeType = .stringAttributeType
        userEmail.isOptional = false
        userProps.append(userEmail)

        let passwordHash = NSAttributeDescription()
        passwordHash.name = "passwordHash"
        passwordHash.attributeType = .stringAttributeType
        passwordHash.isOptional = false
        userProps.append(passwordHash)

        let imageData = NSAttributeDescription()
        imageData.name = "imageData"
        imageData.attributeType = .binaryDataAttributeType
        imageData.isOptional = true
        userProps.append(imageData)

        let userCreatedAt = NSAttributeDescription()
        userCreatedAt.name = "createdAt"
        userCreatedAt.attributeType = .dateAttributeType
        userCreatedAt.isOptional = false
        userProps.append(userCreatedAt)

        userEntity.properties = userProps

        model.entities = [reportEntity, userEntity]
        return model
    }
}

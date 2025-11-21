import Foundation
import CoreData
import UIKit
import CryptoKit

protocol UserRepository {
    func createUser(name: String, email: String, password: String) throws -> User
    func getUser(byEmail email: String) throws -> (user: User, objectID: NSManagedObjectID)?
    func getUserObject(byId id: UUID) throws -> (user: User, objectID: NSManagedObjectID)?
    func authenticate(email: String, password: String) throws -> User?
    func updateImage(userId: UUID, image: UIImage?) throws
    func loadImage(userId: UUID) throws -> UIImage?
}

final class CoreDataUserRepository: UserRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func createUser(name: String, email: String, password: String) throws -> User {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "UserEntity", into: context)
        let id = UUID()
        entity.setValue(id, forKey: "id")
        entity.setValue(name, forKey: "name")
        entity.setValue(email.lowercased(), forKey: "email")
        entity.setValue(Self.hash(password), forKey: "passwordHash")
        entity.setValue(Date(), forKey: "createdAt")
        try context.save()
        return User(id: id.uuidString, name: name, email: email.lowercased())
    }

    func getUser(byEmail email: String) throws -> (user: User, objectID: NSManagedObjectID)? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email ==[c] %@", email)
        if let obj = try context.fetch(request).first,
           let id = obj.value(forKey: "id") as? UUID,
           let name = obj.value(forKey: "name") as? String,
           let email = obj.value(forKey: "email") as? String {
            return (User(id: id.uuidString, name: name, email: email), obj.objectID)
        }
        return nil
    }

    func getUserObject(byId id: UUID) throws -> (user: User, objectID: NSManagedObjectID)? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        if let obj = try context.fetch(request).first,
           let id = obj.value(forKey: "id") as? UUID,
           let name = obj.value(forKey: "name") as? String,
           let email = obj.value(forKey: "email") as? String {
            return (User(id: id.uuidString, name: name, email: email), obj.objectID)
        }
        return nil
    }

    func authenticate(email: String, password: String) throws -> User? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "email ==[c] %@", email)
        let hashed = Self.hash(password)
        if let obj = try context.fetch(request).first,
           let storedHash = obj.value(forKey: "passwordHash") as? String,
           storedHash == hashed,
           let id = obj.value(forKey: "id") as? UUID,
           let name = obj.value(forKey: "name") as? String,
           let email = obj.value(forKey: "email") as? String {
            return User(id: id.uuidString, name: name, email: email)
        }
        return nil
    }

    func updateImage(userId: UUID, image: UIImage?) throws {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        guard let obj = try context.fetch(request).first else { return }
        if let image, let data = image.jpegData(compressionQuality: 0.85) {
            obj.setValue(data, forKey: "imageData")
        } else {
            obj.setValue(nil, forKey: "imageData")
        }
        try context.save()
    }

    func loadImage(userId: UUID) throws -> UIImage? {
        let request = NSFetchRequest<NSManagedObject>(entityName: "UserEntity")
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", userId as CVarArg)
        if let obj = try context.fetch(request).first,
           let data = obj.value(forKey: "imageData") as? Data {
            return UIImage(data: data)
        }
        return nil
    }

    private static func hash(_ password: String) -> String {
        let data = Data(password.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

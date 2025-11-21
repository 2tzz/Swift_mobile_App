import Foundation

struct User: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var email: String
}

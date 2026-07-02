import Foundation

/// A captured idea with optional tags.
struct Idea: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var tags: [String]
    var createdAt: Date

    init(id: UUID = UUID(), text: String, tags: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.tags = tags
        self.createdAt = createdAt
    }
}

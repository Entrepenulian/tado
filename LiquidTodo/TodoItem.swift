import Foundation

/// A single to-do. Codable so the whole list persists to UserDefaults as JSON.
struct TodoItem: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isDone: Bool
    var createdAt: Date
    var completedAt: Date?
    /// Non-nil for repeating tasks. These live in the Repeating section.
    var recurrence: Recurrence?

    init(
        id: UUID = UUID(),
        title: String,
        isDone: Bool = false,
        createdAt: Date = Date(),
        completedAt: Date? = nil,
        recurrence: Recurrence? = nil
    ) {
        self.id = id
        self.title = title
        self.isDone = isDone
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.recurrence = recurrence
    }
}

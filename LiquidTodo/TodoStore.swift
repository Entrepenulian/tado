import Foundation

/// Owns the task list and mirrors every change to UserDefaults.
@MainActor
final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = [] {
        didSet { save() }
    }

    private let key = "liquidtodo.items.v1"

    init() { load() }

    // Active items follow the array order (user-rearrangeable via drag).
    // Completed items show most-recently-finished first.
    var active: [TodoItem] {
        items.filter { !$0.isDone }
    }

    var completed: [TodoItem] {
        items.filter { $0.isDone }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    var remainingCount: Int {
        items.reduce(0) { $0 + ($1.isDone ? 0 : 1) }
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed), at: 0)
    }

    /// Reorder an active item so it sits just before `beforeID` in the active list.
    func move(activeID: UUID, beforeID: UUID) {
        guard activeID != beforeID else { return }
        var a = active
        guard let from = a.firstIndex(where: { $0.id == activeID }) else { return }
        let moved = a.remove(at: from)
        if let to = a.firstIndex(where: { $0.id == beforeID }) {
            a.insert(moved, at: to)
        } else {
            a.append(moved)
        }
        items = a + completed
    }

    func toggle(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[i].isDone.toggle()
        items[i].completedAt = items[i].isDone ? Date() : nil
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearCompleted() {
        items.removeAll { $0.isDone }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let decoded = try? JSONDecoder().decode([TodoItem].self, from: data)
        else { return }
        items = decoded
    }
}

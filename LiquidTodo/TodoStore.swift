import Foundation

/// Owns the task list and mirrors every change to UserDefaults.
@MainActor
final class TodoStore: ObservableObject {
    @Published var items: [TodoItem] = [] {
        didSet { save() }
    }

    /// Per-day list of completed task titles for the activity graph and day detail.
    /// Survives clearing/deleting. Day count == the array's length.
    @Published private(set) var completions: [String: [String]] = [:] {
        didSet { saveCompletions() }
    }

    /// Captured ideas (Ideas page). Newest first.
    @Published private(set) var ideas: [Idea] = [] {
        didSet { saveIdeas() }
    }

    private let key = "liquidtodo.items.v1"
    private let completionsKey = "liquidtodo.completions.v1"
    private let ideasKey = "liquidtodo.ideas.v1"
    private var resetTimer: Timer?

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func dayKey(_ date: Date) -> String { dayFormatter.string(from: date) }

    init() {
        load()
        loadCompletions()
        loadIdeas()
        refreshRecurring()
        resetTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshRecurring() }
        }
    }

    // One-time tasks. Active items follow array order (drag-rearrangeable).
    var active: [TodoItem] {
        items.filter { !$0.isDone && $0.recurrence == nil }
    }

    var completed: [TodoItem] {
        items.filter { $0.isDone && $0.recurrence == nil }
            .sorted { ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast) }
    }

    // Repeating tasks live in their own section regardless of done state.
    var repeating: [TodoItem] {
        items.filter { $0.recurrence != nil }
    }

    var remainingCount: Int {
        items.reduce(0) { $0 + ($1.isDone ? 0 : 1) }
    }

    func add(_ title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed), at: 0)
    }

    func addRepeating(_ title: String, recurrence: Recurrence) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        items.insert(TodoItem(title: trimmed, recurrence: recurrence), at: 0)
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
        items = a + repeating + completed
    }

    /// Un-check repeating tasks whose reset boundary has passed.
    func refreshRecurring() {
        let now = Date()
        var updated = items
        var changed = false
        for i in updated.indices {
            guard
                let rec = updated[i].recurrence,
                updated[i].isDone,
                let done = updated[i].completedAt
            else { continue }
            if now >= rec.nextReset(after: done) {
                updated[i].isDone = false
                updated[i].completedAt = nil
                changed = true
            }
        }
        if changed { items = updated }
    }

    func toggle(_ item: TodoItem) {
        guard let i = items.firstIndex(where: { $0.id == item.id }) else { return }
        let nowDone = !items[i].isDone
        items[i].isDone = nowDone
        items[i].completedAt = nowDone ? Date() : nil
        if nowDone {
            recordCompletion(adding: items[i].title)
        } else {
            recordCompletion(removing: items[i].title)
        }
    }

    private func recordCompletion(adding title: String) {
        completions[Self.dayKey(Date()), default: []].append(title)
    }

    private func recordCompletion(removing title: String) {
        let k = Self.dayKey(Date())
        guard var list = completions[k], !list.isEmpty else { return }
        if let idx = list.lastIndex(of: title) {
            list.remove(at: idx)
        } else {
            list.removeLast()
        }
        completions[k] = list.isEmpty ? nil : list
    }

    func delete(_ item: TodoItem) {
        items.removeAll { $0.id == item.id }
    }

    func clearCompleted() {
        items.removeAll { $0.isDone && $0.recurrence == nil }
    }

    // MARK: - Ideas

    func addIdea(_ text: String, tags: [String]) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let cleanTags = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        ideas.insert(Idea(text: trimmed, tags: cleanTags), at: 0)
    }

    func deleteIdea(_ id: UUID) {
        ideas.removeAll { $0.id == id }
    }

    private func saveIdeas() {
        guard let data = try? JSONEncoder().encode(ideas) else { return }
        UserDefaults.standard.set(data, forKey: ideasKey)
    }

    private func loadIdeas() {
        guard
            let data = UserDefaults.standard.data(forKey: ideasKey),
            let decoded = try? JSONDecoder().decode([Idea].self, from: data)
        else { return }
        ideas = decoded
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

    private func saveCompletions() {
        guard let data = try? JSONEncoder().encode(completions) else { return }
        UserDefaults.standard.set(data, forKey: completionsKey)
    }

    private func loadCompletions() {
        guard
            let data = UserDefaults.standard.data(forKey: completionsKey),
            let decoded = try? JSONDecoder().decode([String: [String]].self, from: data)
        else { return }
        // Drop placeholder titles left over from the old count-only format.
        completions = decoded.compactMapValues { titles in
            let cleaned = titles.filter { $0 != "Completed task" }
            return cleaned.isEmpty ? nil : cleaned
        }
    }
}

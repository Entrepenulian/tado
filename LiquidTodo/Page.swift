import Foundation

/// The panel's top-level pages, switched via the header menu.
enum Page: String, CaseIterable, Identifiable {
    case tasks
    case ideas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tasks: "Tasks"
        case .ideas: "Ideas"
        }
    }

    var icon: String {
        switch self {
        case .tasks: "checklist"
        case .ideas: "lightbulb"
        }
    }
}

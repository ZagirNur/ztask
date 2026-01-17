import Foundation

struct Todo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var reminder: Date?
    var isRepeating: Bool
    var hasSubtasks: Bool
    var subtasks: [Subtask]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        reminder: Date? = nil,
        isRepeating: Bool = false,
        hasSubtasks: Bool = false,
        subtasks: [Subtask] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.reminder = reminder
        self.isRepeating = isRepeating
        self.hasSubtasks = hasSubtasks
        self.subtasks = subtasks
        self.createdAt = createdAt
    }
}

struct Subtask: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isCompleted: Bool

    init(id: UUID = UUID(), title: String, isCompleted: Bool = false) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

enum TodoSection: String, CaseIterable {
    case today = "TODAY"
    case tomorrow = "TOMORROW"
    case nextWeek = "NEXT WEEK"
    case later = "LATER"

    var displayName: String {
        return rawValue
    }
}

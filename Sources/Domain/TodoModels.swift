import Foundation

enum TodoSchema {
    static let current = 1
}

struct TodoItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?
    var sortOrder: Int
}

struct TodoStoreFile: Codable, Equatable {
    var schemaVersion: Int
    var items: [TodoItem]
}

struct TodaySections: Equatable {
    var incomplete: [TodoItem]
    var completedToday: [TodoItem]

    var isEmpty: Bool {
        incomplete.isEmpty && completedToday.isEmpty
    }

    static let empty = TodaySections(incomplete: [], completedToday: [])
}

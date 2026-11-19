import Foundation

/// Pure list rules. Does not read or write files.
enum TodoRules {
    /// Trims whitespace. Empty titles are rejected and must not be stored.
    static func normalizedTitle(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    /// Appends a new incomplete item at the end of the incomplete group.
    /// Returns nil when the trimmed title is empty. The input array is not copied in that case.
    static func add(title raw: String, to items: [TodoItem], now: Date, id: UUID = UUID()) -> [TodoItem]? {
        guard let title = normalizedTitle(raw) else { return nil }
        let nextOrder = (items.map(\.sortOrder).max() ?? -1) + 1
        var updated = items
        updated.append(
            TodoItem(
                id: id,
                title: title,
                isCompleted: false,
                createdAt: now,
                completedAt: nil,
                sortOrder: nextOrder
            )
        )
        return updated
    }

    /// Completing sinks the item into today's completed group.
    /// Uncompleting returns it to the end of the incomplete group.
    static func toggle(_ items: [TodoItem], id: UUID, now: Date) -> [TodoItem] {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return items }
        var updated = items
        if updated[index].isCompleted {
            let maxIncomplete = updated.enumerated()
                .filter { $0.offset != index && !$0.element.isCompleted }
                .map(\.element.sortOrder)
                .max() ?? -1
            updated[index].isCompleted = false
            updated[index].completedAt = nil
            updated[index].sortOrder = maxIncomplete + 1
        } else {
            updated[index].isCompleted = true
            updated[index].completedAt = now
        }
        return updated
    }

    /// User delete removes the item. Day rollover must not call this.
    static func delete(_ items: [TodoItem], id: UUID) -> [TodoItem] {
        items.filter { $0.id != id }
    }

    /// Incomplete items from any day, then items completed on `day` only.
    /// Older completed items are omitted from the result and left untouched in `items`.
    static func visibleSections(in items: [TodoItem], on day: Date, calendar: Calendar) -> TodaySections {
        let incomplete = items
            .filter { !$0.isCompleted }
            .sorted(by: incompleteOrder)
        let completedToday = items
            .filter { item in
                guard item.isCompleted, let completedAt = item.completedAt else { return false }
                return calendar.isDate(completedAt, inSameDayAs: day)
            }
            .sorted(by: completedOrder)
        return TodaySections(incomplete: incomplete, completedToday: completedToday)
    }

    private static func incompleteOrder(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        if lhs.sortOrder != rhs.sortOrder { return lhs.sortOrder < rhs.sortOrder }
        return lhs.createdAt < rhs.createdAt
    }

    private static func completedOrder(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        let left = lhs.completedAt ?? .distantPast
        let right = rhs.completedAt ?? .distantPast
        if left != right { return left < right }
        return lhs.sortOrder < rhs.sortOrder
    }
}

import Combine
import Foundation

/// Owns the in-memory list and asks the repository to persist it.
/// Refreshing for a new day only changes what is visible. It never deletes stored items.
@MainActor
final class TodoService: ObservableObject {
    @Published private(set) var sections: TodaySections = .empty
    @Published private(set) var headerDateLine: String = ""
    @Published private(set) var today: Date

    private var items: [TodoItem] = []
    private let repository: TodoFileRepository
    private let clock: DayClock

    init(repository: TodoFileRepository, clock: DayClock) {
        self.repository = repository
        self.clock = clock
        self.today = clock.now
        recompute()
    }

    func load() {
        do {
            items = try repository.load().items
        } catch {
            items = []
        }
        recompute()
    }

    /// Called when the popover opens and when the calendar day changes.
    /// Does not write the file and does not remove older completed items.
    func refreshForCurrentDay() {
        recompute()
    }

    @discardableResult
    func add(title: String) -> Bool {
        guard let updated = TodoRules.add(title: title, to: items, now: clock.now) else {
            return false
        }
        items = updated
        persistAndRecompute()
        return true
    }

    func toggle(id: UUID) {
        items = TodoRules.toggle(items, id: id, now: clock.now)
        persistAndRecompute()
    }

    func delete(id: UUID) {
        items = TodoRules.delete(items, id: id)
        persistAndRecompute()
    }

    private func persistAndRecompute() {
        let file = TodoStoreFile(schemaVersion: TodoSchema.current, items: items)
        try? repository.save(file)
        recompute()
    }

    private func recompute() {
        let now = clock.now
        today = now
        headerDateLine = TodayDateFormatting.headerLine(for: now, calendar: clock.calendar)
        sections = TodoRules.visibleSections(in: items, on: now, calendar: clock.calendar)
    }
}

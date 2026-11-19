import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TodayTodoCore
#endif

struct PersistenceTests {
    private let calendar = TestCalendar.shanghai()

    @Test @MainActor func rejectsEmptyTitleWithoutWriting() throws {
        let url = temporaryStoreURL()
        let clock = ManualDayClock(now: TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar), calendar: calendar)
        let (service, repository) = makeService(clock: clock, fileURL: url)
        #expect(service.add(title: "   ") == false)
        #expect(service.add(title: "\n") == false)
        #expect(service.sections.isEmpty)
        #expect(FileManager.default.fileExists(atPath: url.path) == false)
        let loaded = try repository.load()
        #expect(loaded.items.isEmpty)
        #expect(loaded.schemaVersion == TodoSchema.current)
    }

    @Test @MainActor func addCompleteUncompleteDeleteRoundTrip() throws {
        let url = temporaryStoreURL()
        let now = TestCalendar.date(2026, 11, 19, 9, 30, calendar: calendar)
        let clock = ManualDayClock(now: now, calendar: calendar)
        let (service, repository) = makeService(clock: clock, fileURL: url)

        #expect(service.add(title: " 提交小结 ") == true)
        #expect(service.add(title: "预订会议室") == true)
        #expect(service.sections.incomplete.map(\.title) == ["提交小结", "预订会议室"])

        let first = try #require(service.sections.incomplete.first)
        service.toggle(id: first.id)
        #expect(service.sections.incomplete.map(\.title) == ["预订会议室"])
        #expect(service.sections.completedToday.map(\.title) == ["提交小结"])

        service.toggle(id: first.id)
        #expect(service.sections.incomplete.map(\.title) == ["预订会议室", "提交小结"])
        #expect(service.sections.completedToday.isEmpty)

        let reloadedBeforeDelete = try repository.load()
        #expect(reloadedBeforeDelete.schemaVersion == 1)
        #expect(reloadedBeforeDelete.items.map(\.title) == ["提交小结", "预订会议室"])

        service.delete(id: first.id)
        let (reopened, repositoryAgain) = makeService(clock: clock, fileURL: url)
        #expect(reopened.sections.incomplete.map(\.title) == ["预订会议室"])
        #expect(try repositoryAgain.load().items.map(\.title) == ["预订会议室"])
        #expect(try repositoryAgain.load().schemaVersion == TodoSchema.current)
    }

    @Test @MainActor func saveAndReloadSurvivesNewRepository() throws {
        let url = temporaryStoreURL()
        let created = TestCalendar.date(2026, 11, 18, 8, 0, calendar: calendar)
        let completed = TestCalendar.date(2026, 11, 19, 11, 0, calendar: calendar)
        let clock = ManualDayClock(now: created, calendar: calendar)
        let (service, _) = makeService(clock: clock, fileURL: url)
        #expect(service.add(title: "跨进程") == true)
        let id = try #require(service.sections.incomplete.first?.id)
        clock.now = completed
        service.toggle(id: id)

        let otherClock = ManualDayClock(now: completed, calendar: calendar)
        let (reloaded, repository) = makeService(clock: otherClock, fileURL: url)
        let file = try repository.load()
        #expect(file.schemaVersion == 1)
        #expect(file.items.count == 1)
        #expect(file.items[0].title == "跨进程")
        #expect(file.items[0].isCompleted)
        #expect(file.items[0].completedAt == completed)
        #expect(reloaded.sections.completedToday.map(\.title) == ["跨进程"])
        #expect(reloaded.sections.isEmpty == false)
    }

    @Test func atomicSaveLeavesNoTempFileAndReplacesPreviousContents() throws {
        let url = temporaryStoreURL()
        let repository = TodoFileRepository(fileURL: url)
        let now = TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar)
        let first = TodoStoreFile(
            schemaVersion: 1,
            items: [
                TodoItem(id: UUID(), title: "第一版", isCompleted: false, createdAt: now, completedAt: nil, sortOrder: 0)
            ]
        )
        try repository.save(first)
        let secondID = UUID()
        let second = TodoStoreFile(
            schemaVersion: 1,
            items: first.items + [
                TodoItem(id: secondID, title: "第二版", isCompleted: false, createdAt: now, completedAt: nil, sortOrder: 1)
            ]
        )
        try repository.save(second)

        let directory = url.deletingLastPathComponent()
        let leftovers = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
        #expect(leftovers.map(\.lastPathComponent) == ["todos.json"])
        let data = try Data(contentsOf: url)
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\"schemaVersion\" : 1"))
        #expect(text.hasPrefix("{"))
        #expect(text.trimmingCharacters(in: .whitespacesAndNewlines).hasSuffix("}"))
        let loaded = try repository.load()
        #expect(loaded.items.map(\.id).contains(secondID))
        #expect(loaded.items.count == 2)
    }
}

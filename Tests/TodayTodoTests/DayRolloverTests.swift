import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TodayTodoCore
#endif

struct DayRolloverTests {
    private let calendar = TestCalendar.shanghai()

    @Test func unfinishedItemsCarryForwardAndYesterdaysCompletionsStayStored() {
        let yesterdayNoon = TestCalendar.date(2026, 11, 18, 12, 0, calendar: calendar)
        let yesterdayLate = TestCalendar.date(2026, 11, 18, 23, 59, 30, calendar: calendar)
        let todayMorning = TestCalendar.date(2026, 11, 19, 8, 0, calendar: calendar)

        let unfinishedID = UUID()
        let doneYesterdayID = UUID()
        var items = TodoRules.add(title: "还没做完", to: [], now: yesterdayNoon, id: unfinishedID)!
        items = TodoRules.add(title: "昨天完成", to: items, now: yesterdayNoon, id: doneYesterdayID)!
        items = TodoRules.toggle(items, id: doneYesterdayID, now: yesterdayLate)

        let stillYesterday = TodoRules.visibleSections(in: items, on: yesterdayLate, calendar: calendar)
        #expect(stillYesterday.incomplete.map(\.id) == [unfinishedID])
        #expect(stillYesterday.completedToday.map(\.id) == [doneYesterdayID])

        let today = TodoRules.visibleSections(in: items, on: todayMorning, calendar: calendar)
        #expect(today.incomplete.map(\.title) == ["还没做完"])
        #expect(today.completedToday.isEmpty)
        #expect(today.isEmpty == false)
        #expect(items.contains(where: { $0.id == doneYesterdayID && $0.isCompleted }))
    }

    @Test func midnightBoundaryFrom2359To0000() {
        let late = TestCalendar.date(2026, 11, 19, 23, 59, 59, calendar: calendar)
        let midnight = TestCalendar.date(2026, 11, 20, 0, 0, 0, calendar: calendar)
        let created = TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar)

        let unfinishedID = UUID()
        let completedLateID = UUID()
        let completedAtMidnightID = UUID()
        var items = TodoRules.add(title: "未完成", to: [], now: created, id: unfinishedID)!
        items = TodoRules.add(title: "今晚完成", to: items, now: created, id: completedLateID)!
        items = TodoRules.toggle(items, id: completedLateID, now: late)

        let at2359 = TodoRules.visibleSections(in: items, on: late, calendar: calendar)
        #expect(at2359.incomplete.map(\.title) == ["未完成"])
        #expect(at2359.completedToday.map(\.title) == ["今晚完成"])

        let justAfterMidnight = TodoRules.visibleSections(in: items, on: midnight, calendar: calendar)
        #expect(justAfterMidnight.incomplete.map(\.title) == ["未完成"])
        #expect(justAfterMidnight.completedToday.isEmpty)
        #expect(items.contains(where: { $0.id == completedLateID && $0.isCompleted && $0.completedAt == late }))

        items = TodoRules.add(title: "零点完成", to: items, now: midnight, id: completedAtMidnightID)!
        items = TodoRules.toggle(items, id: completedAtMidnightID, now: midnight)
        let onTheNewDay = TodoRules.visibleSections(in: items, on: midnight, calendar: calendar)
        #expect(onTheNewDay.incomplete.map(\.title) == ["未完成"])
        #expect(onTheNewDay.completedToday.map(\.title) == ["零点完成"])
        #expect(items.contains(where: { $0.id == completedLateID && $0.isCompleted }))
    }

    @Test @MainActor func rolloverKeepsYesterdayCompletedItemsInTheFile() throws {
        let url = temporaryStoreURL()
        let yesterday = TestCalendar.date(2026, 11, 19, 23, 59, 0, calendar: calendar)
        let midnight = TestCalendar.date(2026, 11, 20, 0, 0, 0, calendar: calendar)
        let clock = ManualDayClock(now: yesterday, calendar: calendar)
        let (service, repository) = makeService(clock: clock, fileURL: url)

        #expect(service.add(title: "未完成事项") == true)
        #expect(service.add(title: "昨晚做完") == true)
        let completedID = try #require(service.sections.incomplete.last?.id)
        let unfinishedID = try #require(service.sections.incomplete.first?.id)
        service.toggle(id: completedID)
        #expect(service.sections.completedToday.map(\.id) == [completedID])
        #expect(service.sections.isEmpty == false)

        let before = try repository.load()
        #expect(before.items.contains(where: { $0.id == completedID }))

        clock.now = midnight
        service.refreshForCurrentDay()
        #expect(service.headerDateLine == "11月20日 星期五")
        #expect(service.sections.incomplete.map(\.id) == [unfinishedID])
        #expect(service.sections.completedToday.isEmpty)
        #expect(service.sections.isEmpty == false)

        let afterRefresh = try repository.load()
        #expect(Set(afterRefresh.items.map(\.id)) == Set(before.items.map(\.id)))
        #expect(afterRefresh.items.contains(where: { $0.id == completedID && $0.isCompleted && $0.completedAt == yesterday }))

        #expect(service.add(title: "新的一天") == true)
        let afterSave = try repository.load()
        #expect(afterSave.schemaVersion == 1)
        #expect(afterSave.items.contains(where: { $0.id == completedID && $0.isCompleted }))
        #expect(afterSave.items.contains(where: { $0.title == "新的一天" && $0.isCompleted == false }))
        #expect(service.sections.incomplete.map(\.title) == ["未完成事项", "新的一天"])
        #expect(service.sections.completedToday.isEmpty)
    }

    @Test @MainActor func completedTodayStillShowsAndCompletedOnlyIsNotEmpty() throws {
        let url = temporaryStoreURL()
        let noon = TestCalendar.date(2026, 11, 19, 12, 0, calendar: calendar)
        let clock = ManualDayClock(now: noon, calendar: calendar)
        let (service, repository) = makeService(clock: clock, fileURL: url)
        #expect(service.add(title: "唯一一件") == true)
        let id = try #require(service.sections.incomplete.first?.id)
        service.toggle(id: id)
        #expect(service.sections.incomplete.isEmpty)
        #expect(service.sections.completedToday.map(\.title) == ["唯一一件"])
        #expect(service.sections.isEmpty == false)
        #expect(try repository.load().items.count == 1)
    }

    @Test @MainActor func nilCompletedAtStaysInFileButIsHidden() throws {
        let url = temporaryStoreURL()
        let now = TestCalendar.date(2026, 11, 19, 12, 0, calendar: calendar)
        let orphanID = UUID()
        let repository = TodoFileRepository(fileURL: url)
        try repository.save(
            TodoStoreFile(
                schemaVersion: 1,
                items: [
                    TodoItem(
                        id: orphanID,
                        title: "缺少完成时间",
                        isCompleted: true,
                        createdAt: now,
                        completedAt: nil,
                        sortOrder: 0
                    )
                ]
            )
        )
        let clock = ManualDayClock(now: now, calendar: calendar)
        let (service, _) = makeService(clock: clock, fileURL: url)
        #expect(service.sections.isEmpty)
        let stored = try repository.load()
        #expect(stored.items.map(\.id) == [orphanID])
    }

    @Test func dayChangedNotificationInvokesRefreshCallback() {
        let centerNotifications = NotificationCenter()
        let center = DayRolloverCenter(notificationCenter: centerNotifications, queue: nil)
        var fired = 0
        center.onDayChanged = { fired += 1 }
        center.start()
        centerNotifications.post(name: .NSCalendarDayChanged, object: nil)
        #expect(fired == 1)
        center.stop()
        centerNotifications.post(name: .NSCalendarDayChanged, object: nil)
        #expect(fired == 1)
    }
}

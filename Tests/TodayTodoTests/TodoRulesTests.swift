import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import TodayTodoCore
#endif

struct TodoRulesTests {
    private let calendar = TestCalendar.shanghai()

    @Test func rejectsEmptyAndWhitespaceTitles() {
        #expect(TodoRules.normalizedTitle("   ") == nil)
        #expect(TodoRules.normalizedTitle("\n\t") == nil)
        #expect(TodoRules.normalizedTitle("  买牛奶  ") == "买牛奶")

        let now = TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar)
        let existing = [
            TodoItem(id: UUID(), title: "已有", isCompleted: false, createdAt: now, completedAt: nil, sortOrder: 0)
        ]
        #expect(TodoRules.add(title: "   ", to: existing, now: now) == nil)
        #expect(TodoRules.add(title: "", to: [], now: now) == nil)
    }

    @Test func addAppendsToEndOfIncompleteGroup() {
        let now = TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar)
        let firstID = UUID()
        let secondID = UUID()
        var items = TodoRules.add(title: " 第一件 ", to: [], now: now, id: firstID)!
        items = TodoRules.add(title: "第二件", to: items, now: now, id: secondID)!
        let sections = TodoRules.visibleSections(in: items, on: now, calendar: calendar)
        #expect(sections.incomplete.map(\.title) == ["第一件", "第二件"])
        #expect(sections.incomplete.map(\.id) == [firstID, secondID])
        #expect(sections.incomplete[0].sortOrder < sections.incomplete[1].sortOrder)
        #expect(sections.completedToday.isEmpty)
    }

    @Test func completeSinksAndUncompleteReturnsToEnd() {
        let morning = TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar)
        let noon = TestCalendar.date(2026, 11, 19, 12, 0, calendar: calendar)
        let later = TestCalendar.date(2026, 11, 19, 15, 0, calendar: calendar)
        let a = UUID()
        let b = UUID()
        let c = UUID()
        var items = TodoRules.add(title: "A", to: [], now: morning, id: a)!
        items = TodoRules.add(title: "B", to: items, now: morning, id: b)!
        items = TodoRules.toggle(items, id: a, now: noon)
        var sections = TodoRules.visibleSections(in: items, on: noon, calendar: calendar)
        #expect(sections.incomplete.map(\.title) == ["B"])
        #expect(sections.completedToday.map(\.title) == ["A"])
        #expect(sections.completedToday[0].isCompleted)
        #expect(sections.completedToday[0].completedAt == noon)

        items = TodoRules.add(title: "C", to: items, now: later, id: c)!
        items = TodoRules.toggle(items, id: a, now: later)
        sections = TodoRules.visibleSections(in: items, on: later, calendar: calendar)
        #expect(sections.incomplete.map(\.title) == ["B", "C", "A"])
        #expect(sections.completedToday.isEmpty)
        #expect(sections.incomplete.last?.completedAt == nil)
    }

    @Test func deleteRemovesOnlyTheRequestedItem() {
        let now = TestCalendar.date(2026, 11, 19, 9, 0, calendar: calendar)
        let keep = UUID()
        let drop = UUID()
        var items = TodoRules.add(title: "留下", to: [], now: now, id: keep)!
        items = TodoRules.add(title: "删除", to: items, now: now, id: drop)!
        items = TodoRules.delete(items, id: drop)
        #expect(items.map(\.id) == [keep])
        #expect(TodoRules.delete(items, id: UUID()).map(\.id) == [keep])
    }

    @Test func completedTodayStayVisibleAndSortByCompletionTime() {
        let day = TestCalendar.date(2026, 11, 19, 18, 0, calendar: calendar)
        let early = TestCalendar.date(2026, 11, 19, 10, 0, calendar: calendar)
        let later = TestCalendar.date(2026, 11, 19, 16, 0, calendar: calendar)
        let first = UUID()
        let second = UUID()
        var items = TodoRules.add(title: "先完成", to: [], now: early, id: first)!
        items = TodoRules.add(title: "后完成", to: items, now: early, id: second)!
        items = TodoRules.toggle(items, id: second, now: early)
        items = TodoRules.toggle(items, id: first, now: later)
        let sections = TodoRules.visibleSections(in: items, on: day, calendar: calendar)
        #expect(sections.isEmpty == false)
        #expect(sections.incomplete.isEmpty)
        #expect(sections.completedToday.map(\.title) == ["后完成", "先完成"])
    }

    @Test func headerUsesChineseMonthDayAndWeekday() {
        let thursday = TestCalendar.date(2026, 11, 19, 12, 0, calendar: calendar)
        #expect(TodayDateFormatting.headerLine(for: thursday, calendar: calendar) == "11月19日 星期四")
        let friday = TestCalendar.date(2026, 11, 20, 0, 0, calendar: calendar)
        #expect(TodayDateFormatting.headerLine(for: friday, calendar: calendar) == "11月20日 星期五")
    }
}

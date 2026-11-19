import Foundation
#if SWIFT_PACKAGE
@testable import TodayTodoCore
#endif

enum TestCalendar {
    static func shanghai() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        calendar.locale = Locale(identifier: "zh_CN")
        return calendar
    }

    static func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int = 12,
        _ minute: Int = 0,
        _ second: Int = 0,
        calendar: Calendar = TestCalendar.shanghai()
    ) -> Date {
        calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        )!
    }
}

@MainActor
func makeService(clock: ManualDayClock, fileURL: URL) -> (TodoService, TodoFileRepository) {
    let repository = TodoFileRepository(fileURL: fileURL)
    let service = TodoService(repository: repository, clock: clock)
    service.load()
    return (service, repository)
}

func temporaryStoreURL() -> URL {
    let directory = FileManager.default.temporaryDirectory
        .appendingPathComponent("today-todo-tests-\(UUID().uuidString)", isDirectory: true)
    return directory.appendingPathComponent("todos.json")
}

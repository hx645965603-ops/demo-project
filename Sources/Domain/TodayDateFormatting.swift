import Foundation

enum TodayDateFormatting {
    private static let weekdays = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]

    /// Localized Chinese header line, for example `11月19日 星期四`.
    /// Weekday numbers come from the provided calendar (Gregorian Sunday = 1).
    static func headerLine(for date: Date, calendar: Calendar) -> String {
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        let index = min(max(weekday - 1, 0), weekdays.count - 1)
        return "\(month)月\(day)日 \(weekdays[index])"
    }
}

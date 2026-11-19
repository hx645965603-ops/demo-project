import Foundation

/// Source of "now" and the calendar used to decide which calendar day is today.
/// Production uses `SystemDayClock`. Tests inject `ManualDayClock` so day rollover
/// does not wait for midnight.
protocol DayClock: AnyObject {
    var now: Date { get }
    var calendar: Calendar { get }
}

final class SystemDayClock: DayClock {
    var now: Date { Date() }
    /// `Calendar.current` follows the system time zone. Never pin a zone in production.
    var calendar: Calendar { Calendar.current }
}

final class ManualDayClock: DayClock {
    var now: Date
    var calendar: Calendar

    init(now: Date, calendar: Calendar) {
        self.now = now
        self.calendar = calendar
    }
}

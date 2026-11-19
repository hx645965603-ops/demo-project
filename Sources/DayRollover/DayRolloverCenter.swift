import Foundation

/// Listens for `NSCalendar.dayChangedNotification` and tells the owner to recompute "today".
/// The callback must refresh visibility only. It must not delete stored items.
final class DayRolloverCenter {
    var onDayChanged: (() -> Void)?

    private let notificationCenter: NotificationCenter
    private let queue: OperationQueue?
    private var token: NSObjectProtocol?

    init(notificationCenter: NotificationCenter = .default, queue: OperationQueue? = .main) {
        self.notificationCenter = notificationCenter
        self.queue = queue
    }

    func start() {
        stop()
        token = notificationCenter.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: queue
        ) { [weak self] _ in
            self?.onDayChanged?()
        }
    }

    func stop() {
        if let token {
            notificationCenter.removeObserver(token)
            self.token = nil
        }
    }

    deinit {
        stop()
    }
}

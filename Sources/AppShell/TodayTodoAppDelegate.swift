import AppKit

/// Accessory app: no Dock icon, and closing the popover does not quit.
@MainActor
public final class TodayTodoAppDelegate: NSObject, NSApplicationDelegate {
    private var controller: StatusBarController?
    private var service: TodoService?
    private let rollover = DayRolloverCenter()

    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let repository = TodoFileRepository(fileURL: TodoStoreLocation.defaultFileURL())
        let service = TodoService(repository: repository, clock: SystemDayClock())
        service.load()
        self.service = service

        rollover.onDayChanged = { [weak service] in
            Task { @MainActor in
                service?.refreshForCurrentDay()
            }
        }
        rollover.start()

        let controller = StatusBarController(service: service)
        controller.install()
        self.controller = controller
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}

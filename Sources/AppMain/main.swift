import AppKit
#if SWIFT_PACKAGE
import TodayTodoCore
#endif

@main
enum TodayTodoMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = TodayTodoAppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        // `app.run()` retains this stack frame, which keeps `delegate` alive.
        app.run()
    }
}

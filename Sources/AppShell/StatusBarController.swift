import AppKit

/// Menu bar entry, popover placement, outside click, and Escape.
@MainActor
final class StatusBarController: NSObject {
    private let statusItem: NSStatusItem
    private let panel: TodayPanel
    private let service: TodoService
    private let sizeRelay: SizeRelay
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var localKeyMonitor: Any?

    init(service: TodoService) {
        self.service = service
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        let relay = SizeRelay()
        sizeRelay = relay
        panel = TodayPanel(rootView: TodayRootView(service: service, sizeRelay: relay))
        super.init()
        relay.onChange = { [weak self] size in
            self?.apply(size: size)
        }
        panel.hostingView.layoutSubtreeIfNeeded()
    }

    func install() {
        guard let button = statusItem.button else { return }
        button.image = MenuBarSymbol.makeImage()
        button.imagePosition = .imageOnly
        button.imageScaling = .scaleProportionallyDown
        button.target = self
        button.action = #selector(toggle(_:))
        button.toolTip = "今日待办"
        button.setAccessibilityLabel("今日待办")
    }

    @objc private func toggle(_ sender: Any?) {
        if panel.isVisible {
            close()
        } else {
            open()
        }
    }

    func open() {
        service.refreshForCurrentDay()
        panel.hostingView.layoutSubtreeIfNeeded()
        statusItem.button?.isHighlighted = true
        startMonitors()
        reveal()
    }

    private func reveal() {
        position()
        panel.orderFrontRegardless()
        panel.makeKey()
        activateApp()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .todayTodoPanelDidOpen, object: nil)
        }
    }

    func close() {
        panel.orderOut(nil)
        statusItem.button?.isHighlighted = false
        stopMonitors()
    }

    private func activateApp() {
        if #available(macOS 14.0, *) {
            NSApp.activate()
        } else {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func apply(size: CGSize) {
        guard size.width > 1, size.height > 1 else { return }
        let next = NSSize(width: ceil(size.width), height: ceil(size.height))
        let current = panel.frame.size
        if abs(current.width - next.width) < 0.5, abs(current.height - next.height) < 0.5 {
            return
        }
        panel.setContentSize(next)
        if panel.isVisible {
            position()
        }
    }

    private func position() {
        guard let button = statusItem.button, let buttonWindow = button.window else { return }
        let buttonRect = buttonWindow.convertToScreen(button.convert(button.bounds, to: nil))
        let size = panel.frame.size
        let screen = buttonWindow.screen ?? NSScreen.main
        let visible = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1200, height: 800)
        // The card is centered in the panel. Shadow padding sits outside the card,
        // so the card's top sits one padding below the panel's top.
        let gap: CGFloat = 4
        var origin = NSPoint(
            x: buttonRect.midX - size.width / 2,
            y: buttonRect.minY - gap - size.height + TodayMetrics.shadowPadding
        )
        let minX = visible.minX + 4
        let maxX = visible.maxX - size.width - 4
        if origin.x < minX { origin.x = minX }
        if origin.x > maxX { origin.x = maxX }
        let minY = visible.minY + 4
        if origin.y < minY { origin.y = minY }
        panel.setFrameOrigin(origin)
    }

    private func startMonitors() {
        stopMonitors()
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.close()
            }
        }
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self else { return event }
            if event.window === self.panel || self.isEventOnStatusItem(event) {
                return event
            }
            self.close()
            return event
        }
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }
            Task { @MainActor in
                self?.close()
            }
            return nil
        }
    }

    private func stopMonitors() {
        if let globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        if let localKeyMonitor {
            NSEvent.removeMonitor(localKeyMonitor)
            self.localKeyMonitor = nil
        }
    }

    private func isEventOnStatusItem(_ event: NSEvent) -> Bool {
        guard let button = statusItem.button, event.window === button.window else { return false }
        let local = button.convert(event.locationInWindow, from: nil)
        return button.bounds.contains(local)
    }
}

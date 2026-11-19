import AppKit
import SwiftUI

/// Borderless panel anchored under the status item.
/// `MenuBarExtra` cannot pin the mock's solid light card, 14pt radius, and shadow together
/// while keeping the text field key. `NSPopover` draws an arrow the mockups do not have.
final class TodayPanel: NSPanel {
    let hostingView: NSHostingView<TodayRootView>

    init(rootView: TodayRootView) {
        hostingView = NSHostingView(rootView: rootView)
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 356, height: 348),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        isFloatingPanel = true
        level = .statusBar
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        becomesKeyOnlyIfNeeded = false
        isMovable = false
        titleVisibility = .hidden
        titlebarAppearsTransparent = true
        animationBehavior = .none
        appearance = NSAppearance(named: .aqua)
        hostingView.appearance = NSAppearance(named: .aqua)
        hostingView.sizingOptions = [.intrinsicContentSize]
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        contentView = hostingView
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

import AppKit
import SwiftUI

/// Menu bar symbol. Template monochrome so it follows the menu bar tint.
/// The popover itself stays light.
enum MenuBarSymbol {
    static let systemName = "checkmark.circle"

    static func makeImage() -> NSImage {
        let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .regular)
        let base = NSImage(systemSymbolName: systemName, accessibilityDescription: "今日待办")
        let image = base?.withSymbolConfiguration(configuration) ?? NSImage()
        image.isTemplate = true
        image.size = NSSize(width: 18, height: 18)
        return image
    }
}

struct MenuBarIcon: View {
    var body: some View {
        Image(systemName: MenuBarSymbol.systemName)
            .font(.system(size: 15, weight: .regular))
            .symbolRenderingMode(.monochrome)
            .accessibilityLabel("今日待办")
    }
}

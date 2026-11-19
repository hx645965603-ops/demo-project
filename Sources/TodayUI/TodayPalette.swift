import SwiftUI

/// Light appearance locked to the confirmed mockups. The popover does not follow system dark mode.
enum TodayPalette {
    static let window = Color(red: 0.953, green: 0.961, blue: 0.973)
    static let title = Color(red: 0.09, green: 0.09, blue: 0.11)
    static let body = Color(red: 0.12, green: 0.12, blue: 0.14)
    static let secondary = Color(red: 0.48, green: 0.49, blue: 0.53)
    static let completed = Color(red: 0.55, green: 0.56, blue: 0.60)
    static let hover = Color(red: 0.894, green: 0.906, blue: 0.925)
    static let emptyWell = Color(red: 0.902, green: 0.910, blue: 0.925)
    static let emptyIcon = Color(red: 0.62, green: 0.64, blue: 0.68)
    static let hairline = Color(red: 0.86, green: 0.87, blue: 0.89)
    static let placeholder = Color(red: 0.62, green: 0.64, blue: 0.68)
    static let systemBlue = Color(red: 0.0, green: 0.478, blue: 1.0)
    static let ring = Color(red: 0.74, green: 0.75, blue: 0.78)
}

enum TodayMetrics {
    static let cardWidth: CGFloat = 300
    static let cornerRadius: CGFloat = 14
    static let shadowPadding: CGFloat = 28
    static let rowHeight: CGFloat = 36
    static let rowSpacing: CGFloat = 2
    static let listVerticalPadding: CGFloat = 8
    static let maxListHeight: CGFloat = 320
    static let emptyBodyHeight: CGFloat = 176

    static func listHeight(rowCount: Int) -> CGFloat {
        guard rowCount > 0 else { return 0 }
        let gaps = CGFloat(max(rowCount - 1, 0)) * rowSpacing
        let content = CGFloat(rowCount) * rowHeight + gaps + listVerticalPadding
        return min(content, maxListHeight)
    }
}

import SwiftUI

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(TodayPalette.emptyWell)
                    .frame(width: 52, height: 52)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 24, weight: .regular))
                    .foregroundStyle(TodayPalette.emptyIcon)
            }
            .padding(.bottom, 6)
            Text("今天还没有待办")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(TodayPalette.body)
            Text("在下方输入，按回车即可添加")
                .font(.system(size: 12.5))
                .foregroundStyle(TodayPalette.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: TodayMetrics.emptyBodyHeight)
        .accessibilityElement(children: .combine)
    }
}

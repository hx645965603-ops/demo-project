import SwiftUI

struct TodoRowView: View {
    let item: TodoItem
    var onToggle: () -> Void
    var onDelete: () -> Void

    var forcedHover = false
    @State private var hovering = false

    private var showsHover: Bool { hovering || forcedHover }

    var body: some View {
        HStack(spacing: 4) {
            Button(action: onToggle) {
                HStack(spacing: 10) {
                    statusIcon
                    titleLabel
                        .font(.system(size: 14))
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isCompleted ? "标为未完成 \(item.title)" : "标为完成 \(item.title)")

            if showsHover {
                Button(action: onDelete) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(TodayPalette.secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("删除 \(item.title)")
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, showsHover ? 6 : 10)
        .frame(height: TodayMetrics.rowHeight)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(showsHover ? TodayPalette.hover : Color.clear)
        )
        .padding(.horizontal, 6)
        .onHover { hovering = $0 }
    }

    private var titleLabel: Text {
        var attributed = AttributedString(item.title)
        if item.isCompleted {
            attributed.foregroundColor = TodayPalette.completed
            attributed.strikethroughStyle = .single
        } else {
            attributed.foregroundColor = TodayPalette.body
        }
        return Text(attributed)
    }

    @ViewBuilder
    private var statusIcon: some View {
        if item.isCompleted {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(TodayPalette.systemBlue)
                .frame(width: 18, height: 18)
        } else {
            Circle()
                .stroke(TodayPalette.ring, lineWidth: 1.25)
                .frame(width: 16, height: 16)
                .frame(width: 18, height: 18)
        }
    }
}

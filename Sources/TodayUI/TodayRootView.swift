import SwiftUI

extension Notification.Name {
    static let todayTodoPanelDidOpen = Notification.Name("TodayTodo.panelDidOpen")
}

/// Reports the rendered popover size, including the shadow margin, so the panel can hug the card.
final class SizeRelay {
    var onChange: ((CGSize) -> Void)?
}

/// Popover content. Reads the domain service only; it does not touch the JSON file.
struct TodayRootView: View {
    @ObservedObject var service: TodoService
    var sizeRelay: SizeRelay
    var forcedHoverID: UUID? = nil

    @State private var draft = ""
    @FocusState private var fieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            TodayHeader(dateLine: service.headerDateLine)
            if service.sections.isEmpty {
                EmptyStateView()
            } else {
                TodoListView(
                    sections: service.sections,
                    forcedHoverID: forcedHoverID,
                    onToggle: { service.toggle(id: $0) },
                    onDelete: { service.delete(id: $0) }
                )
            }
            AddTodoBar(text: $draft, isFocused: $fieldFocused, onSubmit: submit)
        }
        .frame(width: TodayMetrics.cardWidth)
        .fixedSize(horizontal: false, vertical: true)
        .background(TodayPalette.window)
        .clipShape(RoundedRectangle(cornerRadius: TodayMetrics.cornerRadius, style: .continuous))
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 8)
        .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1)
        .padding(TodayMetrics.shadowPadding)
        .fixedSize()
        .background(sizeReporter)
        .preferredColorScheme(.light)
        .onAppear { fieldFocused = true }
        .onReceive(NotificationCenter.default.publisher(for: .todayTodoPanelDidOpen)) { _ in
            fieldFocused = true
        }
    }

    private var sizeReporter: some View {
        GeometryReader { geo in
            Color.clear.preference(key: PanelSizeKey.self, value: geo.size)
        }
        .onPreferenceChange(PanelSizeKey.self) { size in
            sizeRelay.onChange?(size)
        }
    }

    private func submit() {
        let accepted = service.add(title: draft)
        if accepted || TodoRules.normalizedTitle(draft) == nil {
            draft = ""
        }
        fieldFocused = true
    }
}

private struct PanelSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next.width > 0, next.height > 0 {
            value = next
        }
    }
}

import SwiftUI

struct TodoListView: View {
    let sections: TodaySections
    var forcedHoverID: UUID? = nil
    var onToggle: (UUID) -> Void
    var onDelete: (UUID) -> Void

    var body: some View {
        let rowCount = sections.incomplete.count + sections.completedToday.count
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: TodayMetrics.rowSpacing) {
                ForEach(sections.incomplete) { item in
                    TodoRowView(
                        item: item,
                        onToggle: { onToggle(item.id) },
                        onDelete: { onDelete(item.id) },
                        forcedHover: item.id == forcedHoverID
                    )
                }
                ForEach(sections.completedToday) { item in
                    TodoRowView(
                        item: item,
                        onToggle: { onToggle(item.id) },
                        onDelete: { onDelete(item.id) },
                        forcedHover: item.id == forcedHoverID
                    )
                }
            }
            .padding(.vertical, 4)
        }
        .frame(height: TodayMetrics.listHeight(rowCount: rowCount))
    }
}

import SwiftUI

private extension View {
    @ViewBuilder func todayTodoFocusRingHidden() -> some View {
        if #available(macOS 14.0, *) {
            self.focusEffectDisabled()
        } else {
            self
        }
    }
}

struct AddTodoBar: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(TodayPalette.hairline)
                .frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(TodayPalette.secondary)
                    .frame(width: 16)
                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text("添加待办...")
                            .font(.system(size: 14))
                            .foregroundStyle(TodayPalette.placeholder)
                            .allowsHitTesting(false)
                    }
                    TextField("", text: $text)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14))
                        .foregroundStyle(TodayPalette.body)
                        .focused(isFocused)
                        .onSubmit(onSubmit)
                        .todayTodoFocusRingHidden()
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
        }
    }
}

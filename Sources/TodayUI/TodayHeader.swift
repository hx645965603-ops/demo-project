import SwiftUI

struct TodayHeader: View {
    let dateLine: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("今天")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(TodayPalette.title)
            Text(dateLine)
                .font(.system(size: 13))
                .foregroundStyle(TodayPalette.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }
}

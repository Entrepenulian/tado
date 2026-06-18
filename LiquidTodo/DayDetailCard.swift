import SwiftUI

/// Side card shown when a day with activity is clicked in the graph.
/// Top third: date + count. Lower two-thirds: the tasks completed that day.
struct DayDetailCard: View {
    let date: Date
    let titles: [String]
    var accent: Color

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(Self.dateFormatter.string(from: date))
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                HStack(spacing: 5) {
                    Text("\(titles.count)")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.tint)
                    Text(titles.count == 1 ? "task completed" : "tasks completed")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider().opacity(0.5)

            ScrollView {
                VStack(spacing: 1) {
                    ForEach(Array(titles.enumerated()), id: \.offset) { _, title in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.tint)
                            Text(title)
                                .font(.system(size: 12.5))
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                    }
                }
                .padding(.vertical, 6)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(width: 232, height: 286)
        .tint(accent)
    }
}

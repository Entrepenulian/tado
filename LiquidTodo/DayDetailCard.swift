import SwiftUI

/// Side card shown beside the panel when a day with activity is clicked.
/// Floats next to the main card, bottom-aligned to it. Sizes to its content,
/// capped at the main card's height (scrolls inside on very busy days).
struct DayDetailCard: View {
    let date: Date
    let titles: [String]
    var accent: Color
    var maxHeight: CGFloat
    var onClose: () -> Void

    @State private var listHeight: CGFloat = 0

    private let headerEstimate: CGFloat = 62

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    var body: some View {
        let listCap = max(maxHeight - headerEstimate, 90)

        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.4).padding(.horizontal, 10)
            ScrollView {
                list
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(key: DayListHeightKey.self, value: proxy.size.height)
                        }
                    )
            }
            .frame(height: min(max(listHeight, 1), listCap))
            .scrollBounceBehavior(.basedOnSize)
            .onPreferenceChange(DayListHeightKey.self) { listHeight = $0 }
        }
        .frame(width: 214)
        .liquidGlass(cornerRadius: 18)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .tint(accent)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.dateFormatter.string(from: date))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                HStack(spacing: 6) {
                    Circle().fill(.tint).frame(width: 6, height: 6)
                    Text("\(titles.count) completed")
                        .font(.system(size: 11.5, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.tertiary)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.top, 11)
        .padding(.bottom, 10)
    }

    private var list: some View {
        VStack(spacing: 3) {
            ForEach(Array(titles.enumerated()), id: \.offset) { _, title in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.tint)
                        .padding(.top, 0.5)
                    Text(title)
                        .font(.system(size: 12))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(10)
    }
}

private struct DayListHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

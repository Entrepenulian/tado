import SwiftUI

/// A GitHub-style contribution graph of task completions.
///
/// Shading is *relative*: each day's level is its count scaled against the
/// busiest day in view. So when little data exists, a few completions read as a
/// strong shade; as you complete more over time, the scale recalibrates.
struct ActivityGraph: View {
    let completions: [String: Int]
    var accent: Color

    private let columns = 17
    private let gap: CGFloat = 3
    // Card content width: panel 320 − body padding (28) − card padding (24).
    private let gridWidth: CGFloat = 268
    private let cal = Calendar.current

    private var cell: CGFloat {
        (gridWidth - CGFloat(columns - 1) * gap) / CGFloat(columns)
    }

    var body: some View {
        let cols = gridColumns()
        let peak = peakCount(in: cols)

        HStack(spacing: gap) {
            ForEach(Array(cols.enumerated()), id: \.offset) { _, column in
                VStack(spacing: gap) {
                    ForEach(Array(column.enumerated()), id: \.offset) { _, day in
                        squircle(for: day, peak: peak)
                    }
                }
            }
        }
        .padding(12)
        .liquidGlass(cornerRadius: 16)
    }

    private func squircle(for day: Date?, peak: Int) -> some View {
        let lvl: Int
        if let day {
            lvl = level(completions[TodoStore.dayKey(day)] ?? 0, peak: peak)
        } else {
            lvl = -1 // future day
        }
        return RoundedRectangle(cornerRadius: cell * 0.28, style: .continuous)
            .fill(color(for: lvl))
            .frame(width: cell, height: cell)
    }

    // MARK: - Dates

    private var today: Date { cal.startOfDay(for: Date()) }

    /// `columns` weeks of 7 days. Future days are `nil`.
    private func gridColumns() -> [[Date?]] {
        let weekStart = cal.date(
            from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today
        let start = cal.date(byAdding: .day, value: -7 * (columns - 1), to: weekStart) ?? today

        var grid: [[Date?]] = []
        for c in 0..<columns {
            var column: [Date?] = []
            for r in 0..<7 {
                let day = cal.date(byAdding: .day, value: c * 7 + r, to: start) ?? start
                column.append(day > today ? nil : day)
            }
            grid.append(column)
        }
        return grid
    }

    private func peakCount(in cols: [[Date?]]) -> Int {
        var peak = 0
        for column in cols {
            for case let day? in column {
                peak = max(peak, completions[TodoStore.dayKey(day)] ?? 0)
            }
        }
        return max(peak, 1)
    }

    // MARK: - Shading

    private func level(_ count: Int, peak: Int) -> Int {
        guard count > 0 else { return 0 }
        return min(4, max(1, Int(ceil(Double(count) / Double(peak) * 4))))
    }

    private func color(for level: Int) -> Color {
        switch level {
        case -1: return .primary.opacity(0.03) // future
        case 0:  return .primary.opacity(0.08) // no activity
        case 1:  return accent.opacity(0.30)
        case 2:  return accent.opacity(0.52)
        case 3:  return accent.opacity(0.74)
        default: return accent                 // level 4
        }
    }
}

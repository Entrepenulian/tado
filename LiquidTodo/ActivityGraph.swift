import SwiftUI

/// A GitHub-style contribution graph of task completions.
///
/// Shading is *relative*: each day's level is its count scaled against the
/// busiest day in view. So when little data exists, a few completions read as a
/// strong shade; as you complete more over time, the scale recalibrates.
///
/// Hover applies a distance-falloff lift (transitions-dev "avatar group hover"):
/// the cell under the cursor grows most, neighbours grow less the farther out
/// they are, and everything springs back on exit.
struct ActivityGraph: View {
    let completions: [String: Int]
    var accent: Color

    private let columns = 17
    private let gap: CGFloat = 3
    // Card content width: panel 320 − body padding (28) − card padding (24).
    private let gridWidth: CGFloat = 268
    private let cal = Calendar.current

    // Hover repel tuning.
    private let pushRadius: CGFloat = 46
    private let maxPush: CGFloat = 3

    @State private var hover: CGPoint?

    private var cell: CGFloat {
        (gridWidth - CGFloat(columns - 1) * gap) / CGFloat(columns)
    }

    var body: some View {
        let cols = gridColumns()
        let peak = peakCount(in: cols)

        HStack(spacing: gap) {
            ForEach(0..<columns, id: \.self) { c in
                VStack(spacing: gap) {
                    ForEach(0..<7, id: \.self) { r in
                        squircle(day: cols[c][r], col: c, row: r, peak: peak)
                    }
                }
            }
        }
        .onContinuousHover { phase in
            switch phase {
            case .active(let location): hover = location
            case .ended: hover = nil
            }
        }
        .padding(12)
        .liquidGlass(cornerRadius: 16)
    }

    private func squircle(day: Date?, col: Int, row: Int, peak: Int) -> some View {
        let lvl: Int
        if let day {
            lvl = level(completions[TodoStore.dayKey(day)] ?? 0, peak: peak)
        } else {
            lvl = -1 // future day
        }
        let push = displacement(col: col, row: row)
        return RoundedRectangle(cornerRadius: cell * 0.28, style: .continuous)
            .fill(color(for: lvl))
            .frame(width: cell, height: cell)
            .offset(x: push.width, y: push.height)
            .animation(.spring(response: 0.32, dampingFraction: 0.74), value: hover)
    }

    /// Push a cell away from the cursor — strongest nearby, fading to zero at `pushRadius`.
    private func displacement(col: Int, row: Int) -> CGSize {
        guard let hover else { return .zero }
        let center = CGPoint(
            x: CGFloat(col) * (cell + gap) + cell / 2,
            y: CGFloat(row) * (cell + gap) + cell / 2
        )
        let dx = center.x - hover.x
        let dy = center.y - hover.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance < pushRadius else { return .zero }

        let direction = distance > 0.001
            ? CGSize(width: dx / distance, height: dy / distance)
            : .zero
        let t = 1 - distance / pushRadius
        let magnitude = maxPush * t * t // ease the falloff
        return CGSize(width: direction.width * magnitude, height: direction.height * magnitude)
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

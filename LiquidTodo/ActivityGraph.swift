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
    let completions: [String: [String]]
    var accent: Color
    @Binding var selectedDay: Date?

    private let columns = 17
    private let gap: CGFloat = 3
    // Card content width: panel 320 − body padding (28) − card padding (24).
    private let gridWidth: CGFloat = 268
    private let cal = Calendar.current

    // Hover repel tuning.
    private let pushSpread: CGFloat = 16 // distance to the peak-push ring
    private let maxPush: CGFloat = 1.3

    @State private var hover: CGPoint?
    @State private var hoveredIndex: Int?
    @State private var showTooltip = false

    private var cell: CGFloat {
        (gridWidth - CGFloat(columns - 1) * gap) / CGFloat(columns)
    }

    var body: some View {
        let cols = gridColumns()
        let peak = peakCount(in: cols)

        VStack(alignment: .leading, spacing: 4) {
            monthHeader(labels: monthLabels(for: cols))

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
                case .active(let location):
                    hover = location
                    let idx = cellIndex(at: location)
                    if idx != hoveredIndex { hoveredIndex = idx }
                case .ended:
                    hover = nil
                    hoveredIndex = nil
                }
            }
            .overlay(alignment: .topLeading) { tooltipOverlay(cols: cols) }
            .task(id: hoveredIndex) {
                withAnimation(.smooth(duration: 0.16)) { showTooltip = false }
                guard hoveredIndex != nil else { return }
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { return }
                withAnimation(.smooth(duration: 0.2)) { showTooltip = true }
            }

            legend
        }
        .padding(12)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Dwell tooltip

    private func cellIndex(at point: CGPoint) -> Int? {
        let stride = cell + gap
        let col = Int(point.x / stride)
        let row = Int(point.y / stride)
        guard col >= 0, col < columns, row >= 0, row < 7 else { return nil }
        return col * 7 + row
    }

    @ViewBuilder
    private func tooltipOverlay(cols: [[Date?]]) -> some View {
        if showTooltip, let idx = hoveredIndex {
            let col = idx / 7
            let row = idx % 7
            if col < cols.count, let day = cols[col][row] {
                let count = completions[TodoStore.dayKey(day)]?.count ?? 0
                tooltip(count: count)
                    .position(
                        x: CGFloat(col) * (cell + gap) + cell / 2,
                        y: CGFloat(row) * (cell + gap) + cell / 2 - 18
                    )
                    .allowsHitTesting(false)
                    .transition(.opacity.combined(with: .scale(scale: 0.9, anchor: .bottom)))
            }
        }
    }

    private func tooltip(count: Int) -> some View {
        Text("\(count) \(count == 1 ? "task" : "tasks")")
            .font(.system(size: 11, weight: .semibold))
            .monospacedDigit()
            .foregroundStyle(.primary)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.regularMaterial, in: Capsule())
            .overlay(Capsule().strokeBorder(.primary.opacity(0.08)))
            .shadow(color: .black.opacity(0.18), radius: 5, y: 1)
    }

    private var legend: some View {
        HStack(spacing: 4) {
            Spacer()
            Image(systemName: "minus")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.tertiary)
            ForEach(0...4, id: \.self) { lvl in
                RoundedRectangle(cornerRadius: 2.8, style: .continuous)
                    .fill(color(for: lvl))
                    .frame(width: 10, height: 10)
            }
            Image(systemName: "plus")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 2)
    }

    // MARK: - Month labels

    private func monthHeader(labels: [String?]) -> some View {
        ZStack(alignment: .topLeading) {
            Color.clear.frame(width: gridWidth, height: 11)
            ForEach(Array(labels.enumerated()), id: \.offset) { c, label in
                if let label {
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .offset(x: CGFloat(c) * (cell + gap))
                }
            }
        }
    }

    /// One label per column where the month changes (min 2 columns apart so they
    /// never overlap). Derived from each week's first day, so it's accurate.
    private func monthLabels(for cols: [[Date?]]) -> [String?] {
        var labels = [String?](repeating: nil, count: cols.count)
        var lastMonth: Int?
        var lastEmit = -10
        for (c, column) in cols.enumerated() {
            guard let day = column.first.flatMap({ $0 }) else { continue }
            let month = cal.component(.month, from: day)
            if month != lastMonth {
                lastMonth = month
                if c - lastEmit >= 2 {
                    labels[c] = Self.monthFormatter.string(from: day)
                    lastEmit = c
                }
            }
        }
        return labels
    }

    private static let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM"
        return f
    }()

    private func squircle(day: Date?, col: Int, row: Int, peak: Int) -> some View {
        let count = day.map { completions[TodoStore.dayKey($0)]?.count ?? 0 } ?? 0
        let lvl = day == nil ? -1 : level(count, peak: peak)
        let push = displacement(col: col, row: row)
        return RoundedRectangle(cornerRadius: cell * 0.28, style: .continuous)
            .fill(color(for: lvl))
            .frame(width: cell, height: cell)
            .offset(x: push.width, y: push.height)
            .animation(trackingAnimation, value: hover)
            .contentShape(Rectangle())
            .onTapGesture {
                guard let day, count > 0 else { return }
                selectedDay = sameDay(selectedDay, day) ? nil : day
            }
    }

    private func sameDay(_ a: Date?, _ b: Date?) -> Bool {
        guard let a, let b else { return false }
        return cal.isDate(a, inSameDayAs: b)
    }

    /// Track the cursor with a fast interactive spring (minimal lag), then
    /// settle softly when the pointer leaves.
    private var trackingAnimation: Animation {
        hover == nil
            ? .spring(response: 0.4, dampingFraction: 0.72)
            : .interactiveSpring(response: 0.15, dampingFraction: 0.9, blendDuration: 0.08)
    }

    /// Push a cell away from the cursor along a smooth blooming-ring field:
    /// displacement rises to a peak in a ring at `pushSpread` and tapers off both
    /// outward (no hard edge) and inward (→0 under the cursor, so no direction flip).
    private func displacement(col: Int, row: Int) -> CGSize {
        guard let hover else { return .zero }
        let center = CGPoint(
            x: CGFloat(col) * (cell + gap) + cell / 2,
            y: CGFloat(row) * (cell + gap) + cell / 2
        )
        let dx = center.x - hover.x
        let dy = center.y - hover.y
        let distance = sqrt(dx * dx + dy * dy)
        guard distance > 0.001 else { return .zero }

        // Normalized Gaussian bump: r·e^(−r²/2), peak 1 at r = 1 (distance == pushSpread).
        let r = distance / pushSpread
        let bump = (r * exp(-r * r / 2)) / 0.606_530_66
        let magnitude = maxPush * bump
        return CGSize(width: dx / distance * magnitude, height: dy / distance * magnitude)
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
                peak = max(peak, completions[TodoStore.dayKey(day)]?.count ?? 0)
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

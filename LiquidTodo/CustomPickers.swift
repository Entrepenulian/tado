import SwiftUI

// MARK: - Custom calendar

/// A hand-built month calendar — no native DatePicker.
struct CustomDatePicker: View {
    @Binding var date: Date
    @State private var month: Date

    private let cal = Calendar.current

    init(date: Binding<Date>) {
        _date = date
        let comps = Calendar.current.dateComponents([.year, .month], from: date.wrappedValue)
        _month = State(initialValue: Calendar.current.date(from: comps) ?? date.wrappedValue)
    }

    var body: some View {
        VStack(spacing: 8) {
            header
            weekdayRow
            grid
        }
        .padding(.top, 4)
    }

    private var header: some View {
        HStack {
            Text(monthTitle)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
            Spacer()
            chevron("chevron.left") { shift(-1) }
            chevron("chevron.right") { shift(1) }
        }
        .padding(.horizontal, 2)
    }

    private func chevron(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var weekdayRow: some View {
        HStack(spacing: 2) {
            ForEach(Array(orderedSymbols.enumerated()), id: \.offset) { _, sym in
                Text(sym)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var grid: some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)
        return LazyVGrid(columns: columns, spacing: 4) {
            ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                if let day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 32)
                }
            }
        }
        .animation(.smooth(duration: 0.2), value: month)
    }

    private func dayCell(_ day: Int) -> some View {
        let selected = isSameDay(day, as: date)
        let today = isSameDay(day, as: Date())
        return ZStack {
            if selected {
                Circle().fill(.tint).frame(width: 28, height: 28)
            } else if today {
                Circle().stroke(.tint.opacity(0.5), lineWidth: 1).frame(width: 28, height: 28)
            }
            Text("\(day)")
                .font(.system(size: 12, weight: selected ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(selected ? AnyShapeStyle(.white)
                                 : today ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
        }
        .frame(maxWidth: .infinity, minHeight: 32)
        .contentShape(Rectangle())
        .onTapGesture { withAnimation(.smooth(duration: 0.2)) { select(day) } }
    }

    // MARK: data

    private var monthTitle: String {
        let f = DateFormatter()
        f.dateFormat = "LLLL yyyy"
        return f.string(from: month)
    }

    private var orderedSymbols: [String] {
        let s = cal.veryShortWeekdaySymbols
        let start = cal.firstWeekday - 1
        return Array(s[start...] + s[..<start])
    }

    private var cells: [Int?] {
        let firstOfMonth = cal.date(from: cal.dateComponents([.year, .month], from: month)) ?? month
        let weekday = cal.component(.weekday, from: firstOfMonth)
        let leading = (weekday - cal.firstWeekday + 7) % 7
        let days = cal.range(of: .day, in: .month, for: firstOfMonth)?.count ?? 30
        return Array(repeating: nil, count: leading) + (1...days).map { Optional($0) }
    }

    private func dateFor(_ day: Int) -> Date? {
        var comps = cal.dateComponents([.year, .month], from: month)
        comps.day = day
        return cal.date(from: comps)
    }

    private func isSameDay(_ day: Int, as other: Date) -> Bool {
        guard let d = dateFor(day) else { return false }
        return cal.isDate(d, inSameDayAs: other)
    }

    private func select(_ day: Int) {
        if let d = dateFor(day) { date = d }
    }

    private func shift(_ n: Int) {
        if let m = cal.date(byAdding: .month, value: n, to: month) {
            withAnimation(.smooth(duration: 0.2)) { month = m }
        }
    }
}

// MARK: - Custom time picker

/// Hour / minute steppers with an AM/PM toggle — no native DatePicker.
struct CustomTimePicker: View {
    @Binding var date: Date
    private let cal = Calendar.current

    private var hour24: Int { cal.component(.hour, from: date) }
    private var minute: Int { cal.component(.minute, from: date) }
    private var hour12: Int { let h = hour24 % 12; return h == 0 ? 12 : h }
    private var isPM: Bool { hour24 >= 12 }

    var body: some View {
        HStack(spacing: 8) {
            StepperColumn(text: String(format: "%02d", hour12),
                          onUp: { changeHour(1) }, onDown: { changeHour(-1) })
            Text(":")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            StepperColumn(text: String(format: "%02d", minute),
                          onUp: { changeMinute(5) }, onDown: { changeMinute(-5) })

            VStack(spacing: 4) {
                ampm("AM", selected: !isPM) { setTime(pm: false) }
                ampm("PM", selected: isPM) { setTime(pm: true) }
            }
            .padding(.leading, 2)
        }
        .padding(.top, 6)
        .frame(maxWidth: .infinity)
    }

    private func ampm(_ label: String, selected: Bool, _ action: @escaping () -> Void) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(selected ? .white : .secondary)
            .frame(width: 38, height: 24)
            .background {
                if selected { Capsule().fill(.tint) }
            }
            .contentShape(Capsule())
            .onTapGesture { withAnimation(.smooth(duration: 0.2)) { action() } }
    }

    private func setTime(hour12 h12: Int? = nil, minute m: Int? = nil, pm: Bool? = nil) {
        let useHour12 = h12 ?? hour12
        let usePM = pm ?? isPM
        var h = useHour12 % 12
        if usePM { h += 12 }
        var comps = cal.dateComponents([.year, .month, .day], from: date)
        comps.hour = h
        comps.minute = m ?? minute
        if let d = cal.date(from: comps) { date = d }
    }

    private func changeHour(_ delta: Int) {
        var h = hour12 + delta
        if h > 12 { h = 1 }
        if h < 1 { h = 12 }
        setTime(hour12: h)
    }

    private func changeMinute(_ delta: Int) {
        var m = minute + delta
        if m >= 60 { m = 0 }
        if m < 0 { m = 55 }
        setTime(minute: m)
    }
}

private struct StepperColumn: View {
    let text: String
    let onUp: () -> Void
    let onDown: () -> Void

    var body: some View {
        VStack(spacing: 2) {
            chevron("chevron.up", onUp)
            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 34)
            chevron("chevron.down", onDown)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.primary.opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func chevron(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: name)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

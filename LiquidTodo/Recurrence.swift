import Foundation

/// How and when a repeating task resets.
struct Recurrence: Codable, Equatable {
    enum Frequency: String, Codable, CaseIterable, Identifiable {
        case daily, weekly, monthly
        var id: String { rawValue }
        var label: String {
            switch self {
            case .daily: "Daily"
            case .weekly: "Weekly"
            case .monthly: "Monthly"
            }
        }
    }

    var frequency: Frequency
    var startDate: Date
    var resetTime: Date

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f
    }()

    /// e.g. "Daily · resets 9:00 AM"
    var summary: String {
        "\(frequency.label) · resets \(Self.timeFormatter.string(from: resetTime))"
    }

    /// The first reset boundary strictly after `date`.
    func nextReset(after date: Date) -> Date {
        let cal = Calendar.current
        let t = cal.dateComponents([.hour, .minute], from: resetTime)
        func atResetTime(_ d: Date) -> Date {
            cal.date(bySettingHour: t.hour ?? 0, minute: t.minute ?? 0, second: 0, of: d) ?? d
        }

        switch frequency {
        case .daily:
            var d = atResetTime(date)
            if d <= date { d = cal.date(byAdding: .day, value: 1, to: d) ?? d }
            return d
        case .weekly:
            return nextMatch(after: date, atResetTime: atResetTime) {
                cal.component(.weekday, from: $0) == cal.component(.weekday, from: startDate)
            }
        case .monthly:
            return nextMatch(after: date, atResetTime: atResetTime) {
                cal.component(.day, from: $0) == cal.component(.day, from: startDate)
            }
        }
    }

    private func nextMatch(after date: Date, atResetTime: (Date) -> Date, matches: (Date) -> Bool) -> Date {
        let cal = Calendar.current
        var d = atResetTime(date)
        var guardCount = 0
        while (d <= date || !matches(d)) && guardCount < 400 {
            d = atResetTime(cal.date(byAdding: .day, value: 1, to: d) ?? d)
            guardCount += 1
        }
        return d
    }
}

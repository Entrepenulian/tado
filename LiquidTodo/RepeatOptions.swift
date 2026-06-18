import SwiftUI

/// The configuration shown when "Repeat Task?" is enabled: a custom segmented
/// frequency selector and two rows that expand to reveal native date/time pickers.
struct RepeatOptions: View {
    @Binding var frequency: Recurrence.Frequency
    @Binding var startDate: Date
    @Binding var resetTime: Date

    var body: some View {
        VStack(spacing: 10) {
            FrequencySelector(selection: $frequency)

            VStack(spacing: 4) {
                PickerRow(icon: "calendar", label: "Starts",
                          value: $startDate, components: .date)
                Divider().opacity(0.25)
                PickerRow(icon: "clock", label: "Reset time",
                          value: $resetTime, components: .hourAndMinute)
            }
            .padding(10)
            .background(.primary.opacity(0.05),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }
}

// MARK: - Frequency selector

private struct FrequencySelector: View {
    @Binding var selection: Recurrence.Frequency
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Recurrence.Frequency.allCases) { freq in
                let selected = freq == selection
                Text(freq.label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(selected ? .white : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background {
                        if selected {
                            Capsule()
                                .fill(.tint)
                                .matchedGeometryEffect(id: "freqPill", in: ns)
                        }
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        withAnimation(.smooth(duration: 0.3)) { selection = freq }
                    }
            }
        }
        .padding(3)
        .background(.primary.opacity(0.07), in: Capsule())
    }
}

// MARK: - Expandable value row

private struct PickerRow: View {
    let icon: String
    let label: String
    @Binding var value: Date
    let components: DatePickerComponents
    @State private var open = false

    private var display: String {
        let f = DateFormatter()
        if components == .date {
            f.dateStyle = .medium
        } else {
            f.timeStyle = .short
        }
        return f.string(from: value)
    }

    var body: some View {
        VStack(spacing: 8) {
            Button {
                withAnimation(.smooth(duration: 0.25)) { open.toggle() }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 16)
                    Text(label)
                        .font(.system(size: 12.5))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(display)
                        .font(.system(size: 12.5, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(open ? AnyShapeStyle(.tint) : AnyShapeStyle(.primary))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            open ? AnyShapeStyle(.tint.opacity(0.14)) : AnyShapeStyle(.primary.opacity(0.07)),
                            in: Capsule()
                        )
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if open {
                DatePicker("", selection: $value, displayedComponents: components)
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

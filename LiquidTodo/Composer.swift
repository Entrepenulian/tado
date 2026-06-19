import SwiftUI

/// A "New ToDo" button that expands into the task-creation form.
struct Composer: View {
    @EnvironmentObject private var store: TodoStore
    @State private var expanded = false
    @State private var hovering = false

    @State private var title = ""
    @State private var repeats = false
    @State private var frequency: Recurrence.Frequency = .daily
    @State private var startDate = Date()
    @State private var resetTime = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()

    @FocusState private var focused: Bool

    private var canAdd: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Group {
            if expanded {
                form.liquidGlass(cornerRadius: 16)
            } else {
                newButton
            }
        }
        .animation(.smooth(duration: 0.3), value: expanded)
    }

    // MARK: - Collapsed

    private var newButton: some View {
        Button {
            withAnimation(.smooth(duration: 0.3)) { expanded = true }
        } label: {
            HStack(spacing: hovering ? 13 : 6) {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                Text("New ToDo")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(.tint, in: Capsule())
        .onHover { h in
            withAnimation(.smooth(duration: 0.25)) { hovering = h }
        }
    }

    // MARK: - Expanded form

    private var form: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("What needs doing?", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($focused)
                .onSubmit { add() }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
                }

            Divider().opacity(0.4)

            HStack {
                Text("Repeat Task?")
                    .font(.system(size: 13, weight: .medium))
                Spacer(minLength: 24)
                Toggle("", isOn: $repeats.animation(.smooth(duration: 0.25)))
                    .labelsHidden()
                    .toggleStyle(.checkbox)
            }

            if repeats {
                RepeatOptions(frequency: $frequency, startDate: $startDate, resetTime: $resetTime)
            }

            HStack(spacing: 8) {
                Button(action: cancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 40, height: 38)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .liquidGlass(cornerRadius: 11)

                Button(action: add) {
                    HStack(spacing: 6) {
                        Text("Add")
                        Image(systemName: "plus")
                    }
                    .font(.system(size: 13, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.white)
                .background(
                    canAdd ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.4)),
                    in: Capsule()
                )
                .disabled(!canAdd)
            }
        }
        .padding(12)
    }

    // MARK: - Actions

    private func add() {
        guard canAdd else { return }
        let text = title
        if repeats {
            store.addRepeating(
                text,
                recurrence: Recurrence(frequency: frequency, startDate: startDate, resetTime: resetTime)
            )
        } else {
            store.add(text)
        }
        reset()
        withAnimation(.smooth(duration: 0.3)) { expanded = false }
    }

    private func cancel() {
        reset()
        withAnimation(.smooth(duration: 0.3)) { expanded = false }
    }

    private func reset() {
        title = ""
        repeats = false
        frequency = .daily
        startDate = Date()
    }
}

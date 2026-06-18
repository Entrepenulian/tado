import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var store: TodoStore
    @State private var showCompleted = false
    @State private var dropTargetID: UUID?
    @State private var checking: Set<UUID> = []

    // #FF6A1A
    private let accent = Color(red: 1.0, green: 0.4157, blue: 0.1020)

    var body: some View {
        VStack(spacing: 12) {
            header
            Composer()
            content
            footer
            activitySection
        }
        .padding(14)
        .frame(width: 320)
        .tint(accent)
        .onAppear { store.refreshRecurring() }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Activity")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)

            ActivityGraph(completions: store.completions, accent: accent)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("Tasks")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
            Spacer()
            Text("\(store.remainingCount)")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 2)
    }

    // MARK: - List

    @ViewBuilder
    private var content: some View {
        if store.items.isEmpty {
            emptyState
        } else {
            VStack(spacing: 2) {
                ForEach(store.active) { item in
                    activeRow(item)
                        .overlay(alignment: .top) {
                            if dropTargetID == item.id {
                                Capsule()
                                    .fill(.tint)
                                    .frame(height: 2)
                                    .padding(.horizontal, 8)
                            }
                        }
                        .draggable(item.id.uuidString) {
                            activeRow(item)
                                .frame(width: 288)
                                .liquidGlass(cornerRadius: 10)
                        }
                        .dropDestination(for: String.self) { dropped, _ in
                            dropTargetID = nil
                            guard
                                let raw = dropped.first,
                                let from = UUID(uuidString: raw)
                            else { return false }
                            withAnimation(.smooth(duration: 0.25)) {
                                store.move(activeID: from, beforeID: item.id)
                            }
                            return true
                        } isTargeted: { targeted in
                            if targeted {
                                dropTargetID = item.id
                            } else if dropTargetID == item.id {
                                dropTargetID = nil
                            }
                        }
                }
                if !store.repeating.isEmpty { repeatingSection }
                if !store.completed.isEmpty { completedSection }
            }
            .padding(4)
            .liquidGlass(cornerRadius: 16)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    private func activeRow(_ item: TodoItem) -> some View {
        TodoRow(
            item: item,
            checked: checking.contains(item.id),
            onToggle: { check(item) },
            onDelete: { withAnimation(.smooth(duration: 0.25)) { store.delete(item) } }
        )
    }

    private func completedRow(_ item: TodoItem) -> some View {
        TodoRow(
            item: item,
            checked: true,
            onToggle: { withAnimation(.smooth(duration: 0.3)) { store.toggle(item) } },
            onDelete: { withAnimation(.smooth(duration: 0.25)) { store.delete(item) } }
        )
    }

    // MARK: - Repeating

    private var repeatingSection: some View {
        VStack(spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: "repeat")
                    .font(.system(size: 10, weight: .bold))
                Text("Repeating")
                    .font(.system(size: 11, weight: .semibold))
                Text("\(store.repeating.count)")
                    .font(.system(size: 11, weight: .medium))
                    .monospacedDigit()
                    .foregroundStyle(.tertiary)
                Spacer()
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)

            ForEach(store.repeating) { item in
                TodoRow(
                    item: item,
                    checked: item.isDone,
                    subtitle: item.recurrence?.summary,
                    onToggle: { withAnimation(.smooth(duration: 0.3)) { store.toggle(item) } },
                    onDelete: { withAnimation(.smooth(duration: 0.25)) { store.delete(item) } }
                )
            }
        }
        .padding(.top, 4)
    }

    /// Fill the checkmark in place, hold a beat, then move the item to Completed.
    private func check(_ item: TodoItem) {
        guard !checking.contains(item.id) else { return }
        withAnimation(.smooth(duration: 0.3)) { _ = checking.insert(item.id) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.smooth(duration: 0.32)) { store.toggle(item) }
            checking.remove(item.id)
        }
    }

    private var completedSection: some View {
        VStack(spacing: 2) {
            Button {
                withAnimation(.smooth(duration: 0.25)) { showCompleted.toggle() }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .rotationEffect(.degrees(showCompleted ? 90 : 0))
                    Text("Completed")
                        .font(.system(size: 11, weight: .semibold))
                    Text("\(store.completed.count)")
                        .font(.system(size: 11, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.tertiary)
                    Spacer()
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if showCompleted {
                ForEach(store.completed) { completedRow($0) }
            }
        }
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No tasks yet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Footer

    @ViewBuilder
    private var footer: some View {
        if !store.completed.isEmpty {
            HStack(spacing: 10) {
                Button("Clear Completed") {
                    withAnimation(.smooth(duration: 0.3)) { store.clearCompleted() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 2)
        }
    }
}

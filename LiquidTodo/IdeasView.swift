import SwiftUI

/// The Ideas page: capture an idea with tags, then browse saved ideas.
struct IdeasView: View {
    @EnvironmentObject private var store: TodoStore

    @State private var draft = ""
    @State private var tagDraft = ""
    @State private var pendingTags: [String] = []
    @State private var editorHeight: CGFloat = 20

    private let maxEditorHeight: CGFloat = 180 // ~10 lines

    private var canAdd: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 12) {
            composer
            if store.ideas.isEmpty {
                emptyState
            } else {
                list
            }
        }
    }

    // MARK: - Composer

    private var composer: some View {
        VStack(alignment: .leading, spacing: 10) {
            ideaEditor

            Divider().opacity(0.35)

            if !pendingTags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(pendingTags, id: \.self) { tag in
                        TagChip(tag: tag) { removeTag(tag) }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Add a tag", text: $tagDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .onSubmit { addTag() }
            }

            Button(action: add) {
                HStack(spacing: 6) {
                    Text("Add Idea")
                    Image(systemName: "plus")
                }
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .foregroundStyle(.white)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background(
                canAdd ? AnyShapeStyle(.tint) : AnyShapeStyle(.tint.opacity(0.4)),
                in: Capsule()
            )
            .disabled(!canAdd)
        }
        .padding(12)
        .liquidGlass(cornerRadius: 16)
    }

    // A native NSTextView that grows with its content up to ~10 lines, then
    // scrolls — reports its exact height so nothing clips.
    private var ideaEditor: some View {
        GrowingTextView(
            text: $draft,
            height: $editorHeight,
            fontSize: 13,
            minHeight: 20,
            maxHeight: maxEditorHeight,
            autoFocus: true
        )
        .frame(height: editorHeight)
        .overlay(alignment: .topLeading) {
            if draft.isEmpty {
                Text("Capture an idea…")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - List

    private var list: some View {
        VStack(spacing: 2) {
            ForEach(store.ideas) { idea in
                IdeaRow(idea: idea) {
                    withAnimation(.smooth(duration: 0.25)) { store.deleteIdea(idea.id) }
                }
            }
        }
        .padding(4)
        .liquidGlass(cornerRadius: 16)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 24, weight: .light))
                .foregroundStyle(.tertiary)
            Text("No ideas yet")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 26)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Actions

    private func add() {
        guard canAdd else { return }
        var tags = pendingTags
        let trailing = tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        if !trailing.isEmpty, !tags.contains(trailing) { tags.append(trailing) }

        withAnimation(.smooth(duration: 0.3)) {
            store.addIdea(draft, tags: tags)
        }
        draft = ""
        tagDraft = ""
        pendingTags = []
    }

    private func addTag() {
        let tag = tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !tag.isEmpty, !pendingTags.contains(tag) else { tagDraft = ""; return }
        withAnimation(.smooth(duration: 0.2)) { pendingTags.append(tag) }
        tagDraft = ""
    }

    private func removeTag(_ tag: String) {
        withAnimation(.smooth(duration: 0.2)) { pendingTags.removeAll { $0 == tag } }
    }
}

// MARK: - Tag chip

struct TagChip: View {
    let tag: String
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.system(size: 11, weight: .medium))
            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.tint)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.tint.opacity(0.15), in: Capsule())
    }
}

// MARK: - Idea row

struct IdeaRow: View {
    let idea: Idea
    let onDelete: () -> Void
    @State private var hovering = false

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(alignment: .top, spacing: 8) {
                Text(idea.text)
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if hovering {
                    Button(action: onDelete) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.6)))
                }
            }

            if !idea.tags.isEmpty {
                FlowLayout(spacing: 5) {
                    ForEach(idea.tags, id: \.self) { TagChip(tag: $0) }
                }
            }

            Text(Self.relativeFormatter.localizedString(for: idea.createdAt, relativeTo: Date()))
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(.primary.opacity(hovering ? 0.05 : 0))
        )
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeOut(duration: 0.15)) { hovering = h } }
    }
}

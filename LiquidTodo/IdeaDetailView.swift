import SwiftUI
import AppKit

/// A sub-page that showcases a single idea and lets you edit its text and tags,
/// copy it, or delete it. Edits save live.
struct IdeaDetailView: View {
    let idea: Idea
    var onBack: () -> Void
    var onDelete: () -> Void
    var onSave: (Idea) -> Void

    @State private var text: String
    @State private var tags: [String]
    @State private var tagDraft = ""
    @State private var editorHeight: CGFloat = 40

    init(idea: Idea, onBack: @escaping () -> Void, onDelete: @escaping () -> Void, onSave: @escaping (Idea) -> Void) {
        self.idea = idea
        self.onBack = onBack
        self.onDelete = onDelete
        self.onSave = onSave
        _text = State(initialValue: idea.text)
        _tags = State(initialValue: idea.tags)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "MMM d, yyyy · h:mm a"
        return f
    }()

    var body: some View {
        VStack(spacing: 12) {
            header
            editorCard
            tagCard
        }
        .onChange(of: text) { _, _ in save() }
        .onChange(of: tags) { _, _ in save() }
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: 8) {
            Button(action: onBack) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Ideas")
                        .font(.system(size: 13, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: copy) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Copy")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help("Delete")
        }
        .padding(.horizontal, 2)
    }

    // MARK: - Editor

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            GrowingTextView(
                text: $text,
                height: $editorHeight,
                fontSize: 14,
                minHeight: 22,
                maxHeight: 320
            )
            .frame(height: editorHeight)

            Text("Created \(Self.dateFormatter.string(from: idea.createdAt))")
                .font(.system(size: 10.5))
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Tags

    private var tagCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "tag")
                    .font(.system(size: 10, weight: .bold))
                Text("Tags")
                    .font(.system(size: 11, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(.secondary)

            if !tags.isEmpty {
                FlowLayout(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        TagChip(tag: tag) { removeTag(tag) }
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                TextField("Add a tag", text: $tagDraft)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12.5))
                    .onSubmit { addTag() }
            }
        }
        .padding(12)
        .liquidGlass(cornerRadius: 16)
    }

    // MARK: - Actions

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        onSave(Idea(id: idea.id, text: trimmed, tags: tags, createdAt: idea.createdAt))
    }

    private func addTag() {
        let tag = tagDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")
        guard !tag.isEmpty, !tags.contains(tag) else { tagDraft = ""; return }
        withAnimation(.smooth(duration: 0.2)) { tags.append(tag) }
        tagDraft = ""
    }

    private func removeTag(_ tag: String) {
        withAnimation(.smooth(duration: 0.2)) { tags.removeAll { $0 == tag } }
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }
}

import SwiftUI
import AppKit

/// A borderless, auto-growing multi-line text input backed by NSTextView.
/// It reports its exact content height so SwiftUI can size to it — growing with
/// wrapped lines and newlines up to `maxHeight`, then scrolling. No clipping.
struct GrowingTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var height: CGFloat
    var fontSize: CGFloat = 13
    var minHeight: CGFloat = 20
    var maxHeight: CGFloat = 180
    var autoFocus: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        scroll.hasVerticalScroller = false
        scroll.hasHorizontalScroller = false
        scroll.autohidesScrollers = true
        scroll.verticalScrollElasticity = .none

        let textView = NSTextView()
        textView.delegate = context.coordinator
        textView.string = text
        textView.font = .systemFont(ofSize: fontSize)
        textView.textColor = .labelColor
        textView.drawsBackground = false
        textView.backgroundColor = .clear
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 0, height: 2)
        textView.textContainer?.lineFragmentPadding = 0
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.minSize = NSSize(width: 0, height: 0)
        textView.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.autoresizingMask = [.width]

        scroll.documentView = textView
        context.coordinator.textView = textView

        DispatchQueue.main.async {
            context.coordinator.recalculateHeight()
            if autoFocus { textView.window?.makeFirstResponder(textView) }
        }
        return scroll
    }

    func updateNSView(_ scroll: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let textView = scroll.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
        context.coordinator.recalculateHeight()
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: GrowingTextView
        weak var textView: NSTextView?

        init(_ parent: GrowingTextView) { self.parent = parent }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
            recalculateHeight()
        }

        func recalculateHeight() {
            guard
                let textView,
                let layoutManager = textView.layoutManager,
                let container = textView.textContainer
            else { return }

            layoutManager.ensureLayout(for: container)
            let contentHeight = layoutManager.usedRect(for: container).height
                + textView.textContainerInset.height * 2
            let clamped = min(max(contentHeight, parent.minHeight), parent.maxHeight)

            if let scroll = textView.enclosingScrollView {
                scroll.hasVerticalScroller = contentHeight > parent.maxHeight + 0.5
            }

            if abs(parent.height - clamped) > 0.5 {
                let binding = parent.$height
                DispatchQueue.main.async { binding.wrappedValue = clamped }
            }
        }
    }
}

import SwiftUI
import AppKit

/// Keeps the menu-bar panel's top edge fixed while its content resizes.
///
/// MenuBarExtra's panel resizes keeping its bottom-left corner fixed, so
/// expanding/collapsing a section makes the top drift and everything above
/// shift. This pins the top-left after every resize so the panel only ever
/// grows/shrinks downward.
struct WindowTopAnchor: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async { context.coordinator.attach(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        if context.coordinator.window == nil {
            DispatchQueue.main.async { context.coordinator.attach(nsView.window) }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        private(set) weak var window: NSWindow?
        private var anchorTopLeft: NSPoint?
        private var resizeObserver: NSObjectProtocol?
        private var moveObserver: NSObjectProtocol?
        private var correcting = false

        func attach(_ window: NSWindow?) {
            guard let window, self.window !== window else { return }
            self.window = window
            anchorTopLeft = NSPoint(x: window.frame.minX, y: window.frame.maxY)

            resizeObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didResizeNotification, object: window, queue: .main
            ) { [weak self] _ in self?.pinTop() }

            // When the system repositions the panel (e.g. on reopen), adopt the
            // new top as the anchor — but ignore our own corrections.
            moveObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification, object: window, queue: .main
            ) { [weak self] _ in
                guard let self, !self.correcting, let w = self.window else { return }
                self.anchorTopLeft = NSPoint(x: w.frame.minX, y: w.frame.maxY)
            }
        }

        private func pinTop() {
            guard let window, let anchor = anchorTopLeft else { return }
            if abs(window.frame.maxY - anchor.y) > 0.5 {
                correcting = true
                window.setFrameTopLeftPoint(anchor)
                correcting = false
            }
        }

        deinit {
            if let resizeObserver { NotificationCenter.default.removeObserver(resizeObserver) }
            if let moveObserver { NotificationCenter.default.removeObserver(moveObserver) }
        }
    }
}

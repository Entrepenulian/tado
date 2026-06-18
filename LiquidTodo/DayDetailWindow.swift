import SwiftUI
import AppKit

/// Hosts the day-detail card in its own borderless child panel that floats
/// beside the main menu-bar window, bottom-aligned to the main card. The card
/// is a separate window — it never widens the main panel.
@MainActor
final class DayPanelController: ObservableObject {
    private var panel: NSPanel?
    private weak var mainWindow: NSWindow?
    private var onAutoDismiss: (() -> Void)?
    private var observers: [NSObjectProtocol] = []

    func attach(_ window: NSWindow, onAutoDismiss: @escaping () -> Void) {
        self.onAutoDismiss = onAutoDismiss
        guard mainWindow !== window else { return }
        teardownObservers()
        mainWindow = window

        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: NSWindow.didResizeNotification, object: window, queue: .main) { [weak self] _ in
            self?.reposition()
        })
        observers.append(center.addObserver(forName: NSWindow.didMoveNotification, object: window, queue: .main) { [weak self] _ in
            self?.reposition()
        })
        observers.append(center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
            self?.onAutoDismiss?()
        })
    }

    func present(_ card: some View) {
        guard let mainWindow else { return }
        let hosting = NSHostingView(rootView: AnyView(card))
        hosting.layoutSubtreeIfNeeded()
        let size = hosting.fittingSize

        let panel: NSPanel
        if let existing = self.panel {
            panel = existing
        } else {
            panel = NSPanel(
                contentRect: NSRect(origin: .zero, size: size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.isFloatingPanel = true
            panel.hidesOnDeactivate = false
            panel.level = mainWindow.level
            self.panel = panel
            mainWindow.addChildWindow(panel, ordered: .above)
        }

        panel.contentView = hosting
        panel.setContentSize(size)
        reposition()
        panel.orderFront(nil)
    }

    func dismiss() {
        guard let panel else { return }
        mainWindow?.removeChildWindow(panel)
        panel.orderOut(nil)
        self.panel = nil
    }

    private func reposition() {
        guard let panel, let mainWindow else { return }
        let main = mainWindow.frame
        let size = panel.frame.size
        let pad: CGFloat = 14   // main window's content inset
        let gap: CGFloat = 6
        let visible = (mainWindow.screen ?? NSScreen.main)?.visibleFrame ?? main

        let y = main.minY + pad                  // bottom-align to the main card
        var x = main.maxX + gap                  // right by default
        if x + size.width > visible.maxX {       // flip left when there's no room
            x = main.minX - gap - size.width
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }

    private func teardownObservers() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
    }
}

/// Resolves the hosting NSWindow so the controller can anchor to it.
struct MainWindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { if let w = view.window { onResolve(w) } }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { if let w = nsView.window { onResolve(w) } }
    }
}

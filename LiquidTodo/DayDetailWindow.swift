import SwiftUI
import AppKit

/// Hosts the day-detail card in its own borderless child panel that floats
/// beside the main menu-bar window, bottom-aligned to the main card. The card
/// is a separate window — it never widens the main panel.
@MainActor
final class DayPanelController: ObservableObject {
    private var panel: NSPanel?
    private weak var mainWindow: NSWindow?
    private var mainCardHeight: CGFloat = 0
    private var onAutoDismiss: (() -> Void)?
    private var observers: [NSObjectProtocol] = []

    /// The measured height of the main card stack (excludes window padding).
    func setMainCardHeight(_ height: CGFloat) {
        guard height > 0, height != mainCardHeight else { return }
        mainCardHeight = height
        reposition()
    }

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

        // Back the card with the same vibrant material the main window uses,
        // so the card's glass layers over an identical base (matching look).
        let backing = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        if let source = Self.findVisualEffect(in: mainWindow.contentView) {
            backing.material = source.material
            backing.blendingMode = source.blendingMode
        } else {
            backing.material = .menu
            backing.blendingMode = .behindWindow
        }
        backing.state = .active
        backing.wantsLayer = true
        backing.layer?.cornerRadius = 18
        backing.layer?.masksToBounds = true
        backing.autoresizingMask = [.width, .height]

        hosting.frame = backing.bounds
        hosting.autoresizingMask = [.width, .height]
        backing.addSubview(hosting)

        panel.contentView = backing
        panel.setContentSize(size)
        reposition()
        panel.orderFront(nil)
    }

    private static func findVisualEffect(in view: NSView?) -> NSVisualEffectView? {
        guard let view else { return nil }
        if let effect = view as? NSVisualEffectView { return effect }
        for sub in view.subviews {
            if let found = findVisualEffect(in: sub) { return found }
        }
        return nil
    }

    func dismiss() {
        guard let panel else { return }
        mainWindow?.removeChildWindow(panel)
        panel.orderOut(nil)
        self.panel = nil
    }

    private func reposition() {
        guard let panel, let mainWindow else { return }
        let win = mainWindow.frame
        let size = panel.frame.size
        let gap: CGFloat = 8
        let cardWidth: CGFloat = 292 // main column width (320 − 2×14 padding)
        let visible = (mainWindow.screen ?? NSScreen.main)?.visibleFrame ?? win

        // The main card sits symmetrically inset inside the window, so its edges
        // are half the leftover space from each window edge.
        let vInset = mainCardHeight > 0 ? (win.height - mainCardHeight) / 2 : 14
        let hInset = (win.width - cardWidth) / 2

        let bottomY = win.minY + vInset
        let cardRightX = win.maxX - hInset
        let cardLeftX = win.minX + hInset

        var x = cardRightX + gap                 // right by default
        if x + size.width > visible.maxX {       // flip left when there's no room
            x = cardLeftX - gap - size.width
        }
        panel.setFrameOrigin(NSPoint(x: x, y: bottomY))
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

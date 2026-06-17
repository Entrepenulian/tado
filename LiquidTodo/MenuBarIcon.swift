import SwiftUI
import AppKit

/// The menu bar centers its label by the label's bounds, which cancels out any
/// `offset`/`alignmentGuide` applied to a child view. To control the number's
/// vertical position we bake the icon + count into a single template image; the
/// menu bar then centers that image as one unit, so `nudge` actually takes effect.
enum MenuBarIcon {
    @MainActor
    static func render(count: Int, nudge: CGFloat) -> NSImage {
        let content = HStack(spacing: 4) {
            Image(systemName: "checklist")
                .font(.system(size: 15, weight: .regular))
            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 13, weight: .regular))
                    .monospacedDigit()
                    .offset(y: nudge)
            }
        }
        .frame(height: 22)
        .foregroundStyle(.black)
        .padding(.horizontal, 1)

        let renderer = ImageRenderer(content: content)
        renderer.scale = NSScreen.main?.backingScaleFactor ?? 2
        let image = renderer.nsImage ?? NSImage(systemSymbolName: "checklist", accessibilityDescription: "tado")!
        image.isTemplate = true
        return image
    }
}

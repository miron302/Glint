import AppKit
import SwiftUI

/// Custom NSWindow subclass so the Settings window can receive `changeFont:`
/// action messages sent by the system Font Panel and forward them into
/// AppSettings — this is what powers "Browse System Fonts…" in Appearance.
final class FontPanelWindow: NSWindow {
    var onFontChange: ((NSFont) -> Void)?

    func changeFont(_ sender: Any?) {
        guard let manager = sender as? NSFontManager else { return }

        let sample = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let picked = manager.convert(sample)

        onFontChange?(picked)
    }
}

final class SettingsWindowController: NSWindowController {

    convenience init() {
        let window = FontPanelWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Glint Settings"
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.center()
        window.onFontChange = { font in
            AppSettings.shared.fontFamily = font.familyName ?? font.fontName
        }

        self.init(window: window)

        let hosting = NSHostingView(rootView: SettingsView())
        window.contentView = hosting

        NotificationCenter.default.addObserver(
            forName: .glintShowFontPanel, object: nil, queue: .main
        ) { [weak self] _ in
            self?.showFontPanel()
        }
    }

    func show() {
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }

    /// Brings up the standard macOS Font Panel, targeting this window so
    /// its `changeFont(_:)` override receives the user's selection.
    func showFontPanel() {
        window?.makeKeyAndOrderFront(nil)
        window?.makeFirstResponder(window)
        NSFontManager.shared.orderFrontFontPanel(nil)
    }
}

extension Notification.Name {
    static let glintShowFontPanel = Notification.Name("glintShowFontPanel")
}

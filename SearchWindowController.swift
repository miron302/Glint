import AppKit
import SwiftUI
import Combine

final class SearchWindowController: NSWindowController, NSWindowDelegate {

    private let engine = SearchEngine()
    private var lossOfFocusMonitor: Any?
    private var cancellable: AnyCancellable?

    private let headerHeight: CGFloat = 76
    private let rowHeight: CGFloat = 48
    private let maxListHeight: CGFloat = 360

    convenience init() {
        let panel = SearchPanel(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 76),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = true
        panel.isMovableByWindowBackground = false
        panel.hidesOnDeactivate = false

        self.init(window: panel)
        panel.delegate = self

        let view = SearchView(engine: engine, onDismiss: { [weak self] in self?.hide() })
        let hosting = NSHostingView(rootView: view)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        hosting.layer?.masksToBounds = false
        panel.contentView = hosting

        cancellable = engine.$results
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results in
                self?.resize(forResultCount: results.count)
            }
    }

    private func resize(forResultCount count: Int) {
        guard let window else { return }
        let listHeight = count == 0 ? 0 : min(CGFloat(count) * rowHeight + 8, maxListHeight)
        let newHeight = headerHeight + listHeight
        var frame = window.frame
        let deltaHeight = newHeight - frame.height
        frame.origin.y -= deltaHeight // grow downward, keep the top edge fixed
        frame.size.height = newHeight
        window.setFrame(frame, display: true, animate: true)
    }

    func toggle() {
        if let window, window.isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let window else { return }
        positionWindow(window)
        engine.reset()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        if AppSettings.shared.closeOnLoseFocus {
            lossOfFocusMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.hide()
            }
        }

        if AppSettings.shared.playSoundOnOpen {
            NSSound(named: "Tink")?.play()
        }
    }

    func hide() {
        window?.orderOut(nil)
        if let lossOfFocusMonitor {
            NSEvent.removeMonitor(lossOfFocusMonitor)
            self.lossOfFocusMonitor = nil
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        if AppSettings.shared.closeOnLoseFocus {
            hide()
        }
    }

    private func positionWindow(_ window: NSWindow) {
        guard let screen = NSScreen.main else { return }
        let width = CGFloat(AppSettings.shared.windowWidth)
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - width / 2
        let y = screenFrame.minY + screenFrame.height * (1 - CGFloat(AppSettings.shared.verticalPosition))
        window.setFrame(NSRect(x: x, y: y, width: width, height: headerHeight), display: true)
    }
}

/// A borderless panel that can still become key so the search field can
/// receive keyboard focus immediately when shown.
final class SearchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

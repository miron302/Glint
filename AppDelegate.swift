import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?
    private var searchWindowController: SearchWindowController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        setupHotkey()
        applyLaunchAtLoginSetting()

        NotificationCenter.default.addObserver(
            self, selector: #selector(handleOpenSettings),
            name: .glintOpenSettings, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleHotkeyChanged),
            name: .glintHotkeyChanged, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(handleIconChanged),
            name: .glintIconChanged, object: nil
        )
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = IconManager.currentMenuBarImage()
        }

        let menu = NSMenu()
        let hotkeyLabel = HotkeyRecorder.label(
            keyCode: AppSettings.shared.hotKeyCode,
            modifiers: AppSettings.shared.hotKeyModifiers
        )
        let toggleItem = NSMenuItem(title: "Show Glint  (\(hotkeyLabel))", action: #selector(toggleSearch), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit Glint", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        item.menu = menu
        statusItem = item
    }

    private func setupHotkey() {
        HotkeyManager.shared.register(
            keyCode: AppSettings.shared.hotKeyCode,
            modifiers: AppSettings.shared.hotKeyModifiers
        ) { [weak self] in
            self?.toggleSearch()
        }
    }

    private func applyLaunchAtLoginSetting() {
        guard #available(macOS 13.0, *) else { return }
        do {
            if AppSettings.shared.launchAtLogin {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Glint: failed to update launch-at-login: \(error)")
        }
    }

    @objc private func toggleSearch() {
        if searchWindowController == nil {
            searchWindowController = SearchWindowController()
        }
        searchWindowController?.toggle()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.show()
    }

    @objc private func handleOpenSettings() {
        openSettings()
    }

    @objc private func handleHotkeyChanged() {
        setupHotkey()
        setupStatusItem() // refresh the label shown in the menu
    }

    @objc private func handleIconChanged() {
        if let button = statusItem?.button {
            button.image = IconManager.currentMenuBarImage()
        }
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

extension Notification.Name {
    static let glintHotkeyChanged = Notification.Name("glintHotkeyChanged")
}

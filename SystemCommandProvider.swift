import AppKit

/// Recognises a small set of built-in commands. Deliberately simple —
/// exactly the kind of thing meant to be forked/extended by whoever's
/// building on top of Glint.
final class SystemCommandProvider: SearchProvider {
    let id = "system"
    let displayName = "System"

    private struct Command {
        let keywords: [String]
        let title: String
        let subtitle: String
        let symbol: String
        let action: () -> Void
    }

    private lazy var commands: [Command] = [
        Command(
            keywords: ["lock", "lock screen"],
            title: "Lock Screen",
            subtitle: "Lock your Mac immediately",
            symbol: "lock.fill",
            action: {
                let task = Process()
                task.launchPath = "/usr/bin/pmset"
                task.arguments = ["displaysleepnow"]
                try? task.run()
            }
        ),
        Command(
            keywords: ["sleep"],
            title: "Sleep",
            subtitle: "Put your Mac to sleep",
            symbol: "moon.fill",
            action: {
                let task = Process()
                task.launchPath = "/usr/bin/pmset"
                task.arguments = ["sleepnow"]
                try? task.run()
            }
        ),
        Command(
            keywords: ["empty trash", "trash"],
            title: "Empty Trash",
            subtitle: "Empty the macOS Trash",
            symbol: "trash.fill",
            action: {
                NSWorkspace.shared.recycle([]) { _, _ in }
                let script = "tell application \"Finder\" to empty trash"
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
            }
        ),
        Command(
            keywords: ["quit glint"],
            title: "Quit Glint",
            subtitle: "Quit the Glint search panel",
            symbol: "power",
            action: { NSApp.terminate(nil) }
        ),
        Command(
            keywords: ["settings", "preferences", "glint settings"],
            title: "Glint Settings",
            subtitle: "Open the settings window",
            symbol: "gearshape.fill",
            action: {
                NotificationCenter.default.post(name: .glintOpenSettings, object: nil)
            }
        )
    ]

    func results(for query: String) async -> [SearchResult] {
        let lowered = query.lowercased()
        return commands.compactMap { command in
            guard command.keywords.contains(where: { $0.contains(lowered) || lowered.contains($0) }) else { return nil }
            return SearchResult(
                title: command.title,
                subtitle: command.subtitle,
                icon: NSImage(systemSymbolName: command.symbol, accessibilityDescription: nil),
                category: .system,
                score: 80,
                action: command.action
            )
        }
    }
}

extension Notification.Name {
    static let glintOpenSettings = Notification.Name("glintOpenSettings")
}

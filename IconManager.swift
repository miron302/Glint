import AppKit
import UniformTypeIdentifiers

/// Resolves whatever the user picked in Settings → Icon into an NSImage for
/// the status item, and handles copying a user-chosen image into app
/// storage so it survives app restarts without holding a stale file handle.
enum IconManager {

    private static var storageDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Glint", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Returns the image that should be shown in the menu bar right now,
    /// based on current AppSettings.
    static func currentMenuBarImage() -> NSImage? {
        let settings = AppSettings.shared
        if settings.useCustomMenuBarIcon, !settings.customMenuBarIconPath.isEmpty,
           let image = NSImage(contentsOfFile: settings.customMenuBarIconPath) {
            image.isTemplate = true
            image.size = NSSize(width: 18, height: 18)
            return image
        }
        let symbol = NSImage(
            systemSymbolName: settings.menuBarSymbol,
            accessibilityDescription: "Glint"
        )
        symbol?.isTemplate = true
        return symbol
    }

    /// Presents an open panel for the user to pick an image, copies it into
    /// app storage, and updates AppSettings on success.
    static func importCustomIcon(completion: @escaping (Bool) -> Void) {
        let panel = NSOpenPanel()
        panel.title = "Choose a Menu Bar Icon"
        panel.allowedContentTypes = [.png, .jpeg, .tiff, .bmp, .gif]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        panel.begin { response in
            guard response == .OK, let url = panel.url else {
                completion(false)
                return
            }
            do {
                let destination = storageDirectory.appendingPathComponent("CustomMenuBarIcon.\(url.pathExtension)")
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: url, to: destination)
                AppSettings.shared.customMenuBarIconPath = destination.path
                AppSettings.shared.useCustomMenuBarIcon = true
                NotificationCenter.default.post(name: .glintIconChanged, object: nil)
                completion(true)
            } catch {
                NSLog("Glint: failed to import custom icon: \(error)")
                completion(false)
            }
        }
    }

    static func resetToDefault() {
        AppSettings.shared.useCustomMenuBarIcon = false
        NotificationCenter.default.post(name: .glintIconChanged, object: nil)
    }
}

extension Notification.Name {
    static let glintIconChanged = Notification.Name("glintIconChanged")
}

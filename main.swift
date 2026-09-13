import AppKit

// Glint runs as a background "accessory" app — no Dock icon, no menu bar
// clutter beyond a single optional status item. It lives in the menu bar
// and pops up its search panel on a global hotkey.

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()

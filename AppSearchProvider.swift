import AppKit

/// Finds installed apps by scanning the usual Applications directories once
/// and re-using the cached list — this is what keeps Glint lightweight
/// compared to launchers that shell out to `mdfind` for every keystroke.
final class AppSearchProvider: SearchProvider {
    let id = "apps"
    let displayName = "Applications"

    private struct AppEntry {
        let name: String
        let url: URL
        let icon: NSImage
    }

    private var cache: [AppEntry] = []
    private var lastScan: Date = .distantPast
    private let rescanInterval: TimeInterval = 120

    private let searchDirectories = [
        "/Applications",
        "/System/Applications",
        "/System/Applications/Utilities",
        (NSHomeDirectory() as NSString).appendingPathComponent("Applications")
    ]

    func results(for query: String) async -> [SearchResult] {
        rescanIfNeeded()
        let lowered = query.lowercased()
        return cache.compactMap { entry -> SearchResult? in
            guard let score = fuzzyScore(name: entry.name.lowercased(), query: lowered) else { return nil }
            return SearchResult(
                title: entry.name,
                subtitle: entry.url.path,
                icon: entry.icon,
                category: .application,
                score: score,
                action: { NSWorkspace.shared.open(entry.url) }
            )
        }
    }

    private func rescanIfNeeded() {
        guard Date().timeIntervalSince(lastScan) > rescanInterval || cache.isEmpty else { return }
        lastScan = Date()
        var found: [AppEntry] = []
        let fm = FileManager.default
        for dir in searchDirectories {
            guard let items = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in items where item.hasSuffix(".app") {
                let url = URL(fileURLWithPath: dir).appendingPathComponent(item)
                let name = (item as NSString).deletingPathExtension
                let icon = NSWorkspace.shared.icon(forFile: url.path)
                found.append(AppEntry(name: name, url: url, icon: icon))
            }
        }
        cache = found
    }

    /// Simple substring + prefix based scoring. Prefix matches and exact
    /// matches rank highest; anything not containing the query is dropped.
    private func fuzzyScore(name: String, query: String) -> Double? {
        guard !query.isEmpty else { return nil }
        if name == query { return 100 }
        if name.hasPrefix(query) { return 90 - Double(name.count - query.count) * 0.1 }
        if name.contains(query) { return 60 - Double(name.count - query.count) * 0.1 }
        return nil
    }
}

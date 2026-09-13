import AppKit

/// Rides on the existing Spotlight metadata index via NSMetadataQuery so
/// Glint never has to maintain its own file index — this is a big part of
/// keeping the app lightweight and battery-friendly.
final class FileSearchProvider: SearchProvider {
    let id = "files"
    let displayName = "Files & Folders"

    func results(for query: String) async -> [SearchResult] {
        guard query.count >= 2 else { return [] }
        return await withCheckedContinuation { continuation in
            let mdQuery = NSMetadataQuery()
            mdQuery.predicate = NSPredicate(
                format: "kMDItemFSName CONTAINS[cd] %@ AND kMDItemContentTypeTree != 'com.apple.application-bundle'",
                query
            )
            mdQuery.searchScopes = [NSMetadataQueryUserHomeScope, NSMetadataQueryLocalComputerScope]
            mdQuery.sortDescriptors = [NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey, ascending: false)]

            var observer: NSObjectProtocol?
            var timeoutTask: DispatchWorkItem?
            var didFinish = false

            func finish() {
                guard !didFinish else { return }
                didFinish = true
                mdQuery.stop()
                if let observer { NotificationCenter.default.removeObserver(observer) }
                timeoutTask?.cancel()

                let items = (mdQuery.results as? [NSMetadataItem]) ?? []
                let mapped: [SearchResult] = items.prefix(20).compactMap { item in
                    guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else { return nil }
                    let name = (item.value(forAttribute: NSMetadataItemFSNameKey) as? String) ?? (path as NSString).lastPathComponent
                    let url = URL(fileURLWithPath: path)
                    let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                    let icon = NSWorkspace.shared.icon(forFile: path)
                    return SearchResult(
                        title: name,
                        subtitle: path.replacingOccurrences(of: NSHomeDirectory(), with: "~"),
                        icon: icon,
                        category: isDirectory ? .folder : .file,
                        score: 40,
                        action: { NSWorkspace.shared.open(url) }
                    )
                }
                continuation.resume(returning: mapped)
            }

            observer = NotificationCenter.default.addObserver(
                forName: .NSMetadataQueryDidFinishGathering,
                object: mdQuery,
                queue: .main
            ) { _ in finish() }

            // Belt-and-braces timeout so a slow index never blocks the UI.
            let timeout = DispatchWorkItem { finish() }
            timeoutTask = timeout
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: timeout)

            DispatchQueue.main.async {
                mdQuery.start()
            }
        }
    }
}

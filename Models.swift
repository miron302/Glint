import AppKit

enum ResultCategory: String {
    case application, file, calculator, web, system, folder

    var label: String {
        switch self {
        case .application: return "Application"
        case .file: return "File"
        case .calculator: return "Calculator"
        case .web: return "Web Search"
        case .system: return "System"
        case .folder: return "Folder"
        }
    }
}

struct SearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: NSImage?
    let category: ResultCategory
    /// Higher scores float to the top of the combined results list.
    let score: Double
    let action: () -> Void
}

/// A provider contributes zero or more results for a given query.
/// New sources (Spotify, browser bookmarks, Homebrew casks, whatever a
/// jailbreak-style plugin author wants) just conform to this and register
/// themselves with SearchEngine — no changes needed elsewhere.
protocol SearchProvider {
    /// Unique, stable key used in AppSettings.enabledProviders.
    var id: String { get }
    var displayName: String { get }
    func results(for query: String) async -> [SearchResult]
}

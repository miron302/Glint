import AppKit

/// Always offers a "search the web" fallback, low priority so it never
/// outranks a real app/file/calculator match.
final class WebSearchProvider: SearchProvider {
    let id = "web"
    let displayName = "Web Search"

    func results(for query: String) async -> [SearchResult] {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let settings = AppSettings.shared
        let template = settings.webSearchEngine == .custom
            ? settings.customSearchURLTemplate
            : settings.webSearchEngine.template

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return [] }
        let urlString = template.replacingOccurrences(of: "%@", with: encoded)
        guard let url = URL(string: urlString) else { return [] }

        return [
            SearchResult(
                title: "Search the web for \u{201C}\(query)\u{201D}",
                subtitle: settings.webSearchEngine.label,
                icon: NSImage(systemSymbolName: "magnifyingglass", accessibilityDescription: nil),
                category: .web,
                score: 5,
                action: { NSWorkspace.shared.open(url) }
            )
        ]
    }
}

import Foundation

@MainActor
final class SearchEngine: ObservableObject {

    @Published private(set) var results: [SearchResult] = []
    @Published var query: String = "" {
        didSet { scheduleSearch() }
    }

    private var providers: [SearchProvider] = [
        AppSearchProvider(),
        CalculatorProvider(),
        FileSearchProvider(),
        SystemCommandProvider(),
        WebSearchProvider()
    ]

    private var searchTask: Task<Void, Never>?

    private func scheduleSearch() {
        searchTask?.cancel()
        let currentQuery = query
        guard !currentQuery.isEmpty else {
            results = []
            return
        }
        searchTask = Task { [weak self] in
            // Small debounce so fast typing doesn't spam file-system lookups.
            try? await Task.sleep(nanoseconds: 60_000_000)
            guard !Task.isCancelled, let self else { return }
            await self.runSearch(currentQuery)
        }
    }

    private func runSearch(_ text: String) async {
        let enabled = AppSettings.shared.enabledProviders
        let active = providers.filter { enabled.contains($0.id) }

        await withTaskGroup(of: [SearchResult].self) { group in
            for provider in active {
                group.addTask { await provider.results(for: text) }
            }
            var combined: [SearchResult] = []
            for await batch in group {
                combined.append(contentsOf: batch)
            }
            if Task.isCancelled { return }
            combined.sort { $0.score > $1.score }
            let capped = Array(combined.prefix(AppSettings.shared.maxResults))
            self.results = capped
        }
    }

    func reset() {
        query = ""
        results = []
        searchTask?.cancel()
    }
}

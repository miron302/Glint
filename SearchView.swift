import SwiftUI

struct SearchView: View {
    @ObservedObject var engine: SearchEngine
    @ObservedObject var settings = AppSettings.shared
    @State private var selectedIndex: Int = 0
    @FocusState private var fieldFocused: Bool

    var onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: settings.fontSize * 0.9))
                    .foregroundStyle(settings.tintColor)

                TextField("Search apps, files, and more…", text: $engine.query)
                    .textFieldStyle(.plain)
                    .font(.glint(settings.fontFamily, size: settings.fontSize, weight: .regular))
                    .focused($fieldFocused)
                    .onSubmit { runSelected() }

                if !engine.query.isEmpty {
                    Button(action: { engine.reset() }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            if !engine.results.isEmpty {
                Divider().opacity(0.25)
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 2) {
                            ForEach(Array(engine.results.enumerated()), id: \.element.id) { index, result in
                                ResultRowView(result: result, isSelected: index == selectedIndex)
                                    .id(index)
                                    .onTapGesture {
                                        selectedIndex = index
                                        run(result)
                                    }
                            }
                        }
                        .padding(8)
                    }
                    .frame(maxHeight: 360)
                    .onChange(of: selectedIndex) { newValue in
                        withAnimation(.easeOut(duration: 0.12)) {
                            proxy.scrollTo(newValue, anchor: .center)
                        }
                    }
                }
            }
        }
        .frame(width: settings.windowWidth)
        .background(GlassBackground())
        .onChange(of: engine.results.count) { _ in selectedIndex = 0 }
        .onAppear { fieldFocused = true }
        .onExitCommand { onDismiss() }
        .background(KeyCaptureView(onKeyDown: handleKeyDown))
    }

    private func handleKeyDown(_ event: NSEvent) -> Bool {
        switch event.keyCode {
        case 125: // down arrow
            guard !engine.results.isEmpty else { return false }
            selectedIndex = min(selectedIndex + 1, engine.results.count - 1)
            return true
        case 126: // up arrow
            guard !engine.results.isEmpty else { return false }
            selectedIndex = max(selectedIndex - 1, 0)
            return true
        case 53: // escape
            onDismiss()
            return true
        default:
            return false
        }
    }

    private func runSelected() {
        guard engine.results.indices.contains(selectedIndex) else { return }
        run(engine.results[selectedIndex])
    }

    private func run(_ result: SearchResult) {
        result.action()
        onDismiss()
    }
}

/// Bridges raw NSEvent key-down handling into SwiftUI, since arrow-key
/// navigation through a list isn't natively exposed by TextField/List here.
struct KeyCaptureView: NSViewRepresentable {
    let onKeyDown: (NSEvent) -> Bool

    func makeNSView(context: Context) -> KeyCaptureNSView {
        let view = KeyCaptureNSView()
        view.onKeyDown = onKeyDown
        return view
    }

    func updateNSView(_ nsView: KeyCaptureNSView, context: Context) {
        nsView.onKeyDown = onKeyDown
    }
}

final class KeyCaptureNSView: NSView {
    var onKeyDown: ((NSEvent) -> Bool)?
    private var monitor: Any?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window != nil else { return event }
            if self.onKeyDown?(event) == true {
                return nil
            }
            return event
        }
    }

    deinit {
        if let monitor { NSEvent.removeMonitor(monitor) }
    }
}

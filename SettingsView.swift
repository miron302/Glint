import SwiftUI
import AppKit

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("General", systemImage: "gearshape") }

            AppearanceSettingsTab()
                .tabItem { Label("Appearance", systemImage: "wand.and.stars") }

            ProvidersSettingsTab()
                .tabItem { Label("Search Sources", systemImage: "magnifyingglass.circle") }

            IconSettingsTab()
                .tabItem { Label("Icon", systemImage: "app.badge") }

            AboutSettingsTab()
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 560, height: 620)
        .padding(20)
    }
}

// MARK: - General

struct GeneralSettingsTab: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var isRecordingHotkey = false
    @State private var recorderMonitor: Any?

    var body: some View {
        Form {
            Section("Global Shortcut") {
                HStack {
                    Text("Open Glint")
                    Spacer()
                    Button(isRecordingHotkey ? "Press a key combo…" : HotkeyRecorder.label(keyCode: settings.hotKeyCode, modifiers: settings.hotKeyModifiers)) {
                        beginRecording()
                    }
                    .buttonStyle(.bordered)
                }
                Text("Click the button, then press any key combination — for example ⌥ Space or ⌘ Shift K.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Behaviour") {
                Toggle("Launch Glint at login", isOn: $settings.launchAtLogin)
                Toggle("Close panel when it loses focus", isOn: $settings.closeOnLoseFocus)
                Toggle("Play a sound when opening", isOn: $settings.playSoundOnOpen)

                Stepper(value: $settings.maxResults, in: 3...15) {
                    Text("Maximum results shown: \(settings.maxResults)")
                }
            }
        }
        .formStyle(.grouped)
    }

    private func beginRecording() {
        isRecordingHotkey = true
        recorderMonitor = HotkeyRecorder.recordNextKeyPress { keyCode, modifiers in
            settings.hotKeyCode = keyCode
            settings.hotKeyModifiers = modifiers
            isRecordingHotkey = false
            NotificationCenter.default.post(name: .glintHotkeyChanged, object: nil)
        }
    }
}

// MARK: - Appearance

struct AppearanceSettingsTab: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        Form {
            Section("Liquid Glass") {
                VStack(alignment: .leading) {
                    Text("Glass tint intensity")
                    Slider(value: $settings.glassIntensity, in: 0...1)
                }
                VStack(alignment: .leading) {
                    Text("Corner roundness")
                    Slider(value: $settings.cornerRadius, in: 8...36)
                }
                ColorPicker("Tint color", selection: Binding(
                    get: { settings.tintColor },
                    set: { settings.tintColor = $0 }
                ))
            }

            Section("Layout") {
                VStack(alignment: .leading) {
                    Text("Panel width: \(Int(settings.windowWidth)) pt")
                    Slider(value: $settings.windowWidth, in: 480...900, step: 10)
                }
                VStack(alignment: .leading) {
                    Text("Text size")
                    Slider(value: $settings.fontSize, in: 16...30, step: 1)
                }
                VStack(alignment: .leading) {
                    Text("Vertical position on screen")
                    Slider(value: $settings.verticalPosition, in: 0.1...0.6)
                }
                Toggle("Show icons in results", isOn: $settings.showIcons)
            }

            Section("Appearance Mode") {
                Picker("Theme", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Font") {
                Picker("Font family", selection: $settings.fontFamily) {
                    ForEach(curatedFontFamilies, id: \.self) { family in
                        Text(family).tag(family)
                    }
                }
                HStack {
                    Text("Currently using \(settings.fontFamily)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Browse System Fonts…") {
                        NotificationCenter.default.post(name: .glintShowFontPanel, object: nil)
                    }
                }
            }

            Section {
                GlassPreview()
                    .frame(height: 90)
                    .frame(maxWidth: .infinity)
            } header: {
                Text("Live Preview")
            }
        }
        .formStyle(.grouped)
    }
}

struct GlassPreview: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        ZStack {
            LinearGradient(colors: [.purple, .blue, .teal], startPoint: .topLeading, endPoint: .bottomTrailing)
                .opacity(0.35)
            HStack(spacing: 12) {
                Image(systemName: "sparkle.magnifyingglass")
                Text("Search apps, files, and more…")
                    .font(.glint(settings.fontFamily, size: 15))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(GlassBackground())
            .padding(20)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Providers

struct ProvidersSettingsTab: View {
    @ObservedObject var settings = AppSettings.shared

    private let allProviders: [(id: String, name: String, description: String)] = [
        ("apps", "Applications", "Search and launch installed apps"),
        ("files", "Files & Folders", "Search your files using the macOS Spotlight index"),
        ("calculator", "Calculator", "Evaluate math expressions instantly"),
        ("system", "System Commands", "Lock screen, sleep, empty trash, and more"),
        ("web", "Web Search", "Fallback web search for anything else")
    ]

    var body: some View {
        Form {
            Section("Enabled Sources") {
                ForEach(allProviders, id: \.id) { provider in
                    Toggle(isOn: binding(for: provider.id)) {
                        VStack(alignment: .leading) {
                            Text(provider.name)
                            Text(provider.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("Web Search Engine") {
                Picker("Engine", selection: $settings.webSearchEngine) {
                    ForEach(WebSearchEngine.allCases) { engine in
                        Text(engine.label).tag(engine)
                    }
                }
                if settings.webSearchEngine == .custom {
                    TextField("URL template, use %@ for the query", text: $settings.customSearchURLTemplate)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func binding(for id: String) -> Binding<Bool> {
        Binding(
            get: { settings.enabledProviders.contains(id) },
            set: { isOn in
                if isOn {
                    settings.enabledProviders.insert(id)
                } else {
                    settings.enabledProviders.remove(id)
                }
            }
        )
    }
}

// MARK: - Icon

struct IconSettingsTab: View {
    @ObservedObject var settings = AppSettings.shared
    @State private var isImporting = false
    @State private var importFailed = false

    private let columns = [GridItem(.adaptive(minimum: 56), spacing: 12)]

    var body: some View {
        Form {
            Section("Menu Bar Icon") {
                Text("Choose a built-in symbol, or use your own image. Square images work best.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(presetMenuBarSymbols, id: \.self) { symbol in
                        Button {
                            settings.menuBarSymbol = symbol
                            settings.useCustomMenuBarIcon = false
                            NotificationCenter.default.post(name: .glintIconChanged, object: nil)
                        } label: {
                            Image(systemName: symbol)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSelected(symbol) ? settings.tintColor.opacity(0.25) : Color.secondary.opacity(0.1))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(isSelected(symbol) ? settings.tintColor : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)

                if settings.useCustomMenuBarIcon, !settings.customMenuBarIconPath.isEmpty {
                    HStack {
                        if let nsImage = NSImage(contentsOfFile: settings.customMenuBarIconPath) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .frame(width: 28, height: 28)
                        }
                        Text("Using your custom image")
                            .font(.callout)
                        Spacer()
                        Button("Remove", role: .destructive) {
                            IconManager.resetToDefault()
                        }
                    }
                }

                HStack {
                    Button("Choose Custom Image…") {
                        IconManager.importCustomIcon { success in
                            importFailed = !success
                        }
                    }
                    if importFailed {
                        Text("Couldn't import that image.")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }

            Section("App Icon") {
                Text("Glint's Dock and Finder icon is set at build time via Resources/AppIcon.icns — replace that file and rebuild to use your own.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func isSelected(_ symbol: String) -> Bool {
        !settings.useCustomMenuBarIcon && settings.menuBarSymbol == symbol
    }
}



struct AboutSettingsTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkle.magnifyingglass")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Glint")
                .font(.title).bold()
            Text("A fast, glassy, endlessly customisable launcher for macOS.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Version 1.0 · Built with SwiftUI & AppKit")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text("Glint runs entirely on-device: no analytics, no network calls except the web search fallback you trigger yourself.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 40)
    }
}

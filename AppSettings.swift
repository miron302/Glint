import SwiftUI
import Combine

/// Every user-facing customisation option lives here, backed by UserDefaults.
/// This is the single source of truth for both the search panel's appearance
/// and its behaviour, so the settings screen and the live panel always agree.
final class AppSettings: ObservableObject {

    static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // MARK: Hotkey

    @Published var hotKeyCode: UInt32 {
        didSet { defaults.set(hotKeyCode, forKey: Keys.hotKeyCode) }
    }
    @Published var hotKeyModifiers: UInt32 {
        didSet { defaults.set(hotKeyModifiers, forKey: Keys.hotKeyModifiers) }
    }

    // MARK: Appearance — Liquid Glass tuning

    @Published var cornerRadius: Double {
        didSet { defaults.set(cornerRadius, forKey: Keys.cornerRadius) }
    }
    @Published var glassIntensity: Double {
        didSet { defaults.set(glassIntensity, forKey: Keys.glassIntensity) }
    }
    @Published var tintColorHex: String {
        didSet { defaults.set(tintColorHex, forKey: Keys.tintColor) }
    }
    @Published var windowWidth: Double {
        didSet { defaults.set(windowWidth, forKey: Keys.windowWidth) }
    }
    @Published var fontSize: Double {
        didSet { defaults.set(fontSize, forKey: Keys.fontSize) }
    }
    @Published var maxResults: Int {
        didSet { defaults.set(maxResults, forKey: Keys.maxResults) }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet { defaults.set(appearanceMode.rawValue, forKey: Keys.appearanceMode) }
    }
    @Published var verticalPosition: Double {
        didSet { defaults.set(verticalPosition, forKey: Keys.verticalPosition) }
    }
    @Published var showIcons: Bool {
        didSet { defaults.set(showIcons, forKey: Keys.showIcons) }
    }
    @Published var fontFamily: String {
        didSet { defaults.set(fontFamily, forKey: Keys.fontFamily) }
    }

    // MARK: Menu bar icon

    @Published var menuBarSymbol: String {
        didSet { defaults.set(menuBarSymbol, forKey: Keys.menuBarSymbol) }
    }
    @Published var useCustomMenuBarIcon: Bool {
        didSet { defaults.set(useCustomMenuBarIcon, forKey: Keys.useCustomMenuBarIcon) }
    }
    @Published var customMenuBarIconPath: String {
        didSet { defaults.set(customMenuBarIconPath, forKey: Keys.customMenuBarIconPath) }
    }

    // MARK: Behaviour

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }
    @Published var closeOnLoseFocus: Bool {
        didSet { defaults.set(closeOnLoseFocus, forKey: Keys.closeOnLoseFocus) }
    }
    @Published var playSoundOnOpen: Bool {
        didSet { defaults.set(playSoundOnOpen, forKey: Keys.playSoundOnOpen) }
    }

    // MARK: Providers

    @Published var enabledProviders: Set<String> {
        didSet { defaults.set(Array(enabledProviders), forKey: Keys.enabledProviders) }
    }
    @Published var webSearchEngine: WebSearchEngine {
        didSet { defaults.set(webSearchEngine.rawValue, forKey: Keys.webSearchEngine) }
    }
    @Published var customSearchURLTemplate: String {
        didSet { defaults.set(customSearchURLTemplate, forKey: Keys.customSearchURLTemplate) }
    }

    var tintColor: Color {
        get { Color(hex: tintColorHex) ?? .accentColor }
        set { tintColorHex = newValue.toHex() ?? tintColorHex }
    }

    private init() {
        hotKeyCode = UInt32(defaults.object(forKey: Keys.hotKeyCode) as? Int ?? 49) // Space
        hotKeyModifiers = UInt32(defaults.object(forKey: Keys.hotKeyModifiers) as? Int ?? optionMask)
        cornerRadius = defaults.object(forKey: Keys.cornerRadius) as? Double ?? 22
        glassIntensity = defaults.object(forKey: Keys.glassIntensity) as? Double ?? 0.55
        tintColorHex = defaults.string(forKey: Keys.tintColor) ?? "#5AC8FA"
        windowWidth = defaults.object(forKey: Keys.windowWidth) as? Double ?? 680
        fontSize = defaults.object(forKey: Keys.fontSize) as? Double ?? 22
        maxResults = defaults.object(forKey: Keys.maxResults) as? Int ?? 8
        appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: Keys.appearanceMode) ?? "") ?? .system
        verticalPosition = defaults.object(forKey: Keys.verticalPosition) as? Double ?? 0.32
        showIcons = defaults.object(forKey: Keys.showIcons) as? Bool ?? true
        fontFamily = defaults.string(forKey: Keys.fontFamily) ?? "System"
        menuBarSymbol = defaults.string(forKey: Keys.menuBarSymbol) ?? "sparkle.magnifyingglass"
        useCustomMenuBarIcon = defaults.object(forKey: Keys.useCustomMenuBarIcon) as? Bool ?? false
        customMenuBarIconPath = defaults.string(forKey: Keys.customMenuBarIconPath) ?? ""
        launchAtLogin = defaults.object(forKey: Keys.launchAtLogin) as? Bool ?? false
        closeOnLoseFocus = defaults.object(forKey: Keys.closeOnLoseFocus) as? Bool ?? true
        playSoundOnOpen = defaults.object(forKey: Keys.playSoundOnOpen) as? Bool ?? false
        if let saved = defaults.array(forKey: Keys.enabledProviders) as? [String] {
            enabledProviders = Set(saved)
        } else {
            enabledProviders = Set(["apps", "files", "calculator", "system", "web"])
        }
        webSearchEngine = WebSearchEngine(rawValue: defaults.string(forKey: Keys.webSearchEngine) ?? "") ?? .duckduckgo
        customSearchURLTemplate = defaults.string(forKey: Keys.customSearchURLTemplate) ?? "https://www.google.com/search?q=%@"
    }

    private enum Keys {
        static let hotKeyCode = "hotKeyCode"
        static let hotKeyModifiers = "hotKeyModifiers"
        static let cornerRadius = "cornerRadius"
        static let glassIntensity = "glassIntensity"
        static let tintColor = "tintColor"
        static let windowWidth = "windowWidth"
        static let fontSize = "fontSize"
        static let maxResults = "maxResults"
        static let appearanceMode = "appearanceMode"
        static let verticalPosition = "verticalPosition"
        static let showIcons = "showIcons"
        static let fontFamily = "fontFamily"
        static let menuBarSymbol = "menuBarSymbol"
        static let useCustomMenuBarIcon = "useCustomMenuBarIcon"
        static let customMenuBarIconPath = "customMenuBarIconPath"
        static let launchAtLogin = "launchAtLogin"
        static let closeOnLoseFocus = "closeOnLoseFocus"
        static let playSoundOnOpen = "playSoundOnOpen"
        static let enabledProviders = "enabledProviders"
        static let webSearchEngine = "webSearchEngine"
        static let customSearchURLTemplate = "customSearchURLTemplate"
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Always Light"
        case .dark: return "Always Dark"
        }
    }
}

enum WebSearchEngine: String, CaseIterable, Identifiable {
    case google, duckduckgo, bing, custom
    var id: String { rawValue }
    var label: String {
        switch self {
        case .google: return "Google"
        case .duckduckgo: return "DuckDuckGo"
        case .bing: return "Bing"
        case .custom: return "Custom…"
        }
    }
    var template: String {
        switch self {
        case .google: return "https://www.google.com/search?q=%@"
        case .duckduckgo: return "https://duckduckgo.com/?q=%@"
        case .bing: return "https://www.bing.com/search?q=%@"
        case .custom: return "" // resolved from AppSettings.customSearchURLTemplate
        }
    }
}

// Carbon-style modifier masks, kept local so HotkeyManager doesn't need to
// import Carbon just for constants.
let optionMask: Int = 1 << 11
let commandMask: Int = 1 << 8
let shiftMask: Int = 1 << 9
let controlMask: Int = 1 << 12

/// A short, curated list of fonts that look good at Spotlight-style sizes.
/// "System" maps to the SF Pro system font. Anything else is looked up by
/// PostScript/family name via Font.custom.
let curatedFontFamilies: [String] = [
    "System",
    "SF Pro Rounded",
    "New York",
    "Helvetica Neue",
    "Avenir Next",
    "Optima",
    "Georgia",
    "Menlo",
    "Futura",
    "Courier New"
]

/// Preset SF Symbols the user can pick for the menu bar icon without
/// providing their own artwork.
let presetMenuBarSymbols: [String] = [
    "sparkle.magnifyingglass",
    "magnifyingglass.circle.fill",
    "bolt.magnifyingglass",
    "wand.and.stars",
    "command.circle.fill",
    "viewfinder.circle.fill",
    "ellipsis.circle.fill",
    "square.grid.2x2.fill"
]

extension Font {
    /// Resolves the user's chosen font family to a SwiftUI Font, falling
    /// back to the system font automatically if the family isn't installed.
    static func glint(_ family: String, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if family == "System" || family.isEmpty {
            return .system(size: size, weight: weight)
        }
        return .custom(family, size: size)
    }
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb), hexSanitized.count == 6 else { return nil }
        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255
        self = Color(red: r, green: g, blue: b)
    }

    func toHex() -> String? {
        guard let components = NSColor(self).usingColorSpace(.deviceRGB) else { return nil }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

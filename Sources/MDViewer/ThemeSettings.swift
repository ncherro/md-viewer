import AppKit
import MDViewerCore

/// The chosen light and dark themes. Changing either posts `didChange` so open
/// windows (and the Settings preview) restyle live.
enum ThemeSettings {
    static let didChange = Notification.Name("MDViewerThemeDidChange")

    static var light: Theme {
        get { Theme.named(UserDefaults.standard.string(forKey: "lightTheme"), dark: false) }
        set { set(newValue.id, forKey: "lightTheme") }
    }

    static var dark: Theme {
        get { Theme.named(UserDefaults.standard.string(forKey: "darkTheme"), dark: true) }
        set { set(newValue.id, forKey: "darkTheme") }
    }

    static var css: String { Theme.css(light: light, dark: dark) }

    /// The page background for whichever appearance is being drawn, so windows
    /// don't flash a different color while the page loads.
    static var windowBackground: NSColor {
        NSColor(name: nil) { appearance in
            let theme = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
            let c = theme.backgroundRGB
            return NSColor(srgbRed: c.red, green: c.green, blue: c.blue, alpha: 1)
        }
    }

    private static func set(_ id: String, forKey key: String) {
        UserDefaults.standard.set(id, forKey: key)
        NotificationCenter.default.post(name: didChange, object: nil)
    }
}

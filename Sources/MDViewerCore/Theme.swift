import Foundation

/// A color theme for the rendered page. The app picks one light and one dark
/// theme; `Theme.css(light:dark:)` turns them into the CSS variables that
/// template.html is styled with.
public struct Theme: Sendable, Equatable, Identifiable {
    public let id: String
    public let name: String
    public let isDark: Bool

    // Page
    let fg: String
    let fgStrong: String
    let fgMuted: String
    public let bg: String
    let bgSubtle: String
    let border: String
    let link: String
    let codeBg: String
    let mark: String // highlight color; drawn translucent
    let accent: String

    // Syntax highlighting
    let comment: String
    let keyword: String
    let string: String
    let number: String
    let function: String
    let type: String
    let variable: String
    let tag: String
    let meta: String

    /// `--name: value;` declarations for every variable template.html uses.
    public var cssVariables: String {
        [
            ("fg", fg), ("fg-strong", fgStrong), ("fg-muted", fgMuted),
            ("bg", bg), ("bg-subtle", bgSubtle),
            ("border", border), ("border-muted", border + "b3"),
            ("link", link), ("code-bg", codeBg), ("mark-bg", mark + "40"),
            ("blockquote", fgMuted), ("accent", accent),
            ("syn-comment", comment), ("syn-keyword", keyword), ("syn-string", string),
            ("syn-number", number), ("syn-function", function), ("syn-type", type),
            ("syn-variable", variable), ("syn-tag", tag), ("syn-meta", meta),
        ]
        .map { "  --\($0.0): \($0.1);" }
        .joined(separator: "\n")
    }

    /// The page stylesheet's theme: `light` normally, `dark` when the page is in dark mode.
    public static func css(light: Theme, dark: Theme) -> String {
        """
        :root {
        \(light.cssVariables)
        }
        @media (prefers-color-scheme: dark) {
        :root {
        \(dark.cssVariables)
        }
        }
        """
    }

    /// Background color as 0–1 sRGB components, for matching the native window to the page.
    public var backgroundRGB: (red: Double, green: Double, blue: Double) {
        let v = UInt32(bg.dropFirst(), radix: 16) ?? 0
        return (Double((v >> 16) & 0xff) / 255, Double((v >> 8) & 0xff) / 255, Double(v & 0xff) / 255)
    }
}

extension Theme {
    public static let defaultLight = roséPineDawn
    public static let defaultDark = oneDarkPro

    public static let all: [Theme] = light + dark
    public static let light: [Theme] = [roséPineDawn, githubLight, oneLight, solarizedLight, catppuccinLatte, gruvboxLight]
    public static let dark: [Theme] = [oneDarkPro, githubDark, dracula, nord, tokyoNight, solarizedDark, catppuccinMocha, gruvboxDark, roséPine]

    /// The theme with this id and variant, falling back to the variant's default.
    public static func named(_ id: String?, dark isDark: Bool) -> Theme {
        (isDark ? dark : light).first { $0.id == id } ?? (isDark ? defaultDark : defaultLight)
    }

    // MARK: Light

    static let roséPineDawn = Theme(
        id: "rose-pine-dawn", name: "Rosé Pine Dawn", isDark: false,
        fg: "#575279", fgStrong: "#3f3b62", fgMuted: "#797593", bg: "#faf4ed", bgSubtle: "#f4ede8",
        border: "#dfdad9", link: "#286983", codeBg: "#f2e9e1", mark: "#ea9d34", accent: "#d7827e",
        comment: "#9893a5", keyword: "#286983", string: "#ea9d34", number: "#907aa9", function: "#d7827e",
        type: "#56949f", variable: "#907aa9", tag: "#b4637a", meta: "#b4637a")

    static let githubLight = Theme(
        id: "github-light", name: "GitHub Light", isDark: false,
        fg: "#1f2328", fgStrong: "#1f2328", fgMuted: "#59636e", bg: "#ffffff", bgSubtle: "#f6f8fa",
        border: "#d1d9e0", link: "#0969da", codeBg: "#eff1f3", mark: "#d4a72c", accent: "#0969da",
        comment: "#59636e", keyword: "#cf222e", string: "#0a3069", number: "#0550ae", function: "#8250df",
        type: "#953800", variable: "#953800", tag: "#116329", meta: "#0550ae")

    static let oneLight = Theme(
        id: "one-light", name: "One Light", isDark: false,
        fg: "#383a42", fgStrong: "#202227", fgMuted: "#696c77", bg: "#fafafa", bgSubtle: "#f0f0f1",
        border: "#dbdbdc", link: "#4078f2", codeBg: "#eaeaeb", mark: "#c18401", accent: "#a626a4",
        comment: "#a0a1a7", keyword: "#a626a4", string: "#50a14f", number: "#986801", function: "#4078f2",
        type: "#c18401", variable: "#e45649", tag: "#e45649", meta: "#0184bc")

    static let solarizedLight = Theme(
        id: "solarized-light", name: "Solarized Light", isDark: false,
        fg: "#657b83", fgStrong: "#586e75", fgMuted: "#93a1a1", bg: "#fdf6e3", bgSubtle: "#eee8d5",
        border: "#ddd6c1", link: "#268bd2", codeBg: "#eee8d5", mark: "#b58900", accent: "#268bd2",
        comment: "#93a1a1", keyword: "#859900", string: "#2aa198", number: "#d33682", function: "#268bd2",
        type: "#b58900", variable: "#cb4b16", tag: "#268bd2", meta: "#cb4b16")

    static let catppuccinLatte = Theme(
        id: "catppuccin-latte", name: "Catppuccin Latte", isDark: false,
        fg: "#4c4f69", fgStrong: "#3c3f58", fgMuted: "#6c6f85", bg: "#eff1f5", bgSubtle: "#e6e9ef",
        border: "#ccd0da", link: "#1e66f5", codeBg: "#dce0e8", mark: "#df8e1d", accent: "#8839ef",
        comment: "#8c8fa1", keyword: "#8839ef", string: "#40a02b", number: "#fe640b", function: "#1e66f5",
        type: "#df8e1d", variable: "#d20f39", tag: "#d20f39", meta: "#179299")

    static let gruvboxLight = Theme(
        id: "gruvbox-light", name: "Gruvbox Light", isDark: false,
        fg: "#3c3836", fgStrong: "#282828", fgMuted: "#7c6f64", bg: "#fbf1c7", bgSubtle: "#f2e5bc",
        border: "#d5c4a1", link: "#076678", codeBg: "#ebdbb2", mark: "#b57614", accent: "#af3a03",
        comment: "#928374", keyword: "#9d0006", string: "#79740e", number: "#8f3f71", function: "#427b58",
        type: "#b57614", variable: "#076678", tag: "#9d0006", meta: "#af3a03")

    // MARK: Dark

    static let oneDarkPro = Theme(
        id: "one-dark-pro", name: "One Dark Pro", isDark: true,
        fg: "#abb2bf", fgStrong: "#d7dae0", fgMuted: "#7f848e", bg: "#282c34", bgSubtle: "#21252b",
        border: "#3e4451", link: "#61afef", codeBg: "#3e4451", mark: "#e5c07b", accent: "#c678dd",
        comment: "#7f848e", keyword: "#c678dd", string: "#98c379", number: "#d19a66", function: "#61afef",
        type: "#e5c07b", variable: "#e06c75", tag: "#e06c75", meta: "#56b6c2")

    static let githubDark = Theme(
        id: "github-dark", name: "GitHub Dark", isDark: true,
        fg: "#e6edf3", fgStrong: "#f0f6fc", fgMuted: "#9198a1", bg: "#0d1117", bgSubtle: "#151b23",
        border: "#3d444d", link: "#4493f8", codeBg: "#262c36", mark: "#bb8009", accent: "#4493f8",
        comment: "#9198a1", keyword: "#ff7b72", string: "#a5d6ff", number: "#79c0ff", function: "#d2a8ff",
        type: "#ffa657", variable: "#ffa657", tag: "#7ee787", meta: "#79c0ff")

    static let dracula = Theme(
        id: "dracula", name: "Dracula", isDark: true,
        fg: "#f8f8f2", fgStrong: "#ffffff", fgMuted: "#a4a8c0", bg: "#282a36", bgSubtle: "#21222c",
        border: "#44475a", link: "#8be9fd", codeBg: "#44475a", mark: "#f1fa8c", accent: "#bd93f9",
        comment: "#6272a4", keyword: "#ff79c6", string: "#f1fa8c", number: "#bd93f9", function: "#50fa7b",
        type: "#8be9fd", variable: "#ffb86c", tag: "#ff79c6", meta: "#ffb86c")

    static let nord = Theme(
        id: "nord", name: "Nord", isDark: true,
        fg: "#d8dee9", fgStrong: "#eceff4", fgMuted: "#8f99ab", bg: "#2e3440", bgSubtle: "#3b4252",
        border: "#434c5e", link: "#88c0d0", codeBg: "#3b4252", mark: "#ebcb8b", accent: "#88c0d0",
        comment: "#616e88", keyword: "#81a1c1", string: "#a3be8c", number: "#b48ead", function: "#88c0d0",
        type: "#8fbcbb", variable: "#d8dee9", tag: "#81a1c1", meta: "#5e81ac")

    static let tokyoNight = Theme(
        id: "tokyo-night", name: "Tokyo Night", isDark: true,
        fg: "#a9b1d6", fgStrong: "#c0caf5", fgMuted: "#787c99", bg: "#1a1b26", bgSubtle: "#16161e",
        border: "#3b4261", link: "#7aa2f7", codeBg: "#292e42", mark: "#e0af68", accent: "#bb9af7",
        comment: "#565f89", keyword: "#bb9af7", string: "#9ece6a", number: "#ff9e64", function: "#7aa2f7",
        type: "#2ac3de", variable: "#73daca", tag: "#f7768e", meta: "#7dcfff")

    static let solarizedDark = Theme(
        id: "solarized-dark", name: "Solarized Dark", isDark: true,
        fg: "#839496", fgStrong: "#93a1a1", fgMuted: "#657b83", bg: "#002b36", bgSubtle: "#073642",
        border: "#1c4f5a", link: "#268bd2", codeBg: "#073642", mark: "#b58900", accent: "#268bd2",
        comment: "#586e75", keyword: "#859900", string: "#2aa198", number: "#d33682", function: "#268bd2",
        type: "#b58900", variable: "#cb4b16", tag: "#268bd2", meta: "#cb4b16")

    static let catppuccinMocha = Theme(
        id: "catppuccin-mocha", name: "Catppuccin Mocha", isDark: true,
        fg: "#bac2de", fgStrong: "#cdd6f4", fgMuted: "#9399b2", bg: "#1e1e2e", bgSubtle: "#181825",
        border: "#45475a", link: "#89b4fa", codeBg: "#313244", mark: "#f9e2af", accent: "#cba6f7",
        comment: "#9399b2", keyword: "#cba6f7", string: "#a6e3a1", number: "#fab387", function: "#89b4fa",
        type: "#f9e2af", variable: "#f38ba8", tag: "#f38ba8", meta: "#94e2d5")

    static let gruvboxDark = Theme(
        id: "gruvbox-dark", name: "Gruvbox Dark", isDark: true,
        fg: "#ebdbb2", fgStrong: "#fbf1c7", fgMuted: "#a89984", bg: "#282828", bgSubtle: "#32302f",
        border: "#504945", link: "#83a598", codeBg: "#3c3836", mark: "#fabd2f", accent: "#fe8019",
        comment: "#928374", keyword: "#fb4934", string: "#b8bb26", number: "#d3869b", function: "#8ec07c",
        type: "#fabd2f", variable: "#83a598", tag: "#fb4934", meta: "#fe8019")

    static let roséPine = Theme(
        id: "rose-pine", name: "Rosé Pine", isDark: true,
        fg: "#e0def4", fgStrong: "#f2f0ff", fgMuted: "#908caa", bg: "#191724", bgSubtle: "#1f1d2e",
        border: "#403d52", link: "#9ccfd8", codeBg: "#26233a", mark: "#f6c177", accent: "#ebbcba",
        comment: "#6e6a86", keyword: "#31748f", string: "#f6c177", number: "#c4a7e7", function: "#ebbcba",
        type: "#9ccfd8", variable: "#c4a7e7", tag: "#eb6f92", meta: "#eb6f92")
}

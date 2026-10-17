import Foundation
import Testing
@testable import MDViewerCore

@Suite struct ThemeTests {
    @Test func idsAreUniqueAndVariantsSorted() {
        #expect(Set(Theme.all.map(\.id)).count == Theme.all.count)
        #expect(Theme.light.allSatisfy { !$0.isDark })
        #expect(Theme.dark.allSatisfy { $0.isDark })
    }

    @Test func defaultsAreTheOriginalThemes() {
        #expect(Theme.defaultLight.name == "Rosé Pine Dawn")
        #expect(Theme.defaultDark.name == "One Dark Pro")
        #expect(Theme.defaultLight.cssVariables.contains("--bg: #faf4ed;"))
        #expect(Theme.defaultDark.cssVariables.contains("--bg: #282c34;"))
    }

    @Test func namedFallsBackToTheVariantDefault() {
        #expect(Theme.named("nord", dark: true).name == "Nord")
        #expect(Theme.named("nord", dark: false) == Theme.defaultLight) // wrong variant
        #expect(Theme.named("gone", dark: true) == Theme.defaultDark)
        #expect(Theme.named(nil, dark: false) == Theme.defaultLight)
    }

    @Test(arguments: Theme.all)
    func colorsAreValidHex(theme: Theme) {
        let hex = try! Regex("^#[0-9a-f]{6}([0-9a-f]{2})?$")
        for line in theme.cssVariables.split(separator: "\n") {
            let value = line.split(separator: ":")[1].trimmingCharacters(in: CharacterSet(charactersIn: " ;"))
            #expect(value.wholeMatch(of: hex) != nil, "\(theme.id): \(line)")
        }
    }

    /// Every `var(--x)` in template.html must be defined by every theme.
    @Test func definesEveryVariableTheTemplateUses() throws {
        let template = try String(contentsOf: Fixtures.repoRoot.appendingPathComponent("Resources/template.html"), encoding: .utf8)
        let used = Set(template.matches(of: #/var\(--([\w-]+)\)/#).map { String($0.1) })
        #expect(!used.isEmpty)
        for theme in Theme.all {
            let defined = Set(theme.cssVariables.matches(of: #/--([\w-]+):/#).map { String($0.1) })
            #expect(used.subtracting(defined).isEmpty, "\(theme.id) is missing \(used.subtracting(defined))")
        }
    }

    @Test func cssSwitchesOnColorScheme() {
        let css = Theme.css(light: Theme.defaultLight, dark: Theme.defaultDark)
        let parts = css.components(separatedBy: "@media (prefers-color-scheme: dark)")
        #expect(parts.count == 2)
        #expect(parts[0].contains("--bg: #faf4ed;"))
        #expect(parts[1].contains("--bg: #282c34;"))
    }

    @Test func backgroundRGB() {
        let c = Theme.defaultDark.backgroundRGB // #282c34
        #expect(c.red == 0x28 / 255.0 && c.green == 0x2c / 255.0 && c.blue == 0x34 / 255.0)
    }

    @Test func recognizesMarkdownFiles() {
        #expect(Markdown.isMarkdownFile(URL(fileURLWithPath: "/a/README.md")))
        #expect(Markdown.isMarkdownFile(URL(fileURLWithPath: "/a/notes.MARKDOWN")))
        #expect(!Markdown.isMarkdownFile(URL(fileURLWithPath: "/a/pic.png")))
        #expect(!Markdown.isMarkdownFile(URL(string: "https://example.com/README.md")!))
    }
}

import AppKit
import MDViewerCore
import WebKit

/// Settings → theme pickers for light and dark mode, each with a live preview.
/// Choices apply immediately to every open window.
final class SettingsWindowController: NSWindowController, WKNavigationDelegate {
    private let lightPopup = NSPopUpButton()
    private let darkPopup = NSPopUpButton()
    private let lightPreview = SettingsWindowController.makePreview(.aqua)
    private let darkPreview = SettingsWindowController.makePreview(.darkAqua)
    private var loaded: Set<ObjectIdentifier> = []

    private static let sample = """
        # Heading
        Some **bold**, *italic* and `inline code`, plus [a link](#).

        > A blockquote.

        - [x] Done
        - [ ] Not yet

        ```swift
        // Say hello
        func greet(_ name: String) -> String {
            return "Hello, \\(name)! " + String(42)
        }
        ```

        | Theme | Mode |
        |-------|------|
        | This  | Here |
        """

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 860, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        super.init(window: window)

        configure(lightPopup, themes: Theme.light, selected: ThemeSettings.light)
        configure(darkPopup, themes: Theme.dark, selected: ThemeSettings.dark)

        let columns = NSStackView(views: [
            column("Light theme:", lightPopup, lightPreview),
            column("Dark theme:", darkPopup, darkPreview),
        ])
        columns.distribution = .fillEqually
        columns.spacing = 20
        columns.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        window.contentView = columns
        window.center()

        for preview in [lightPreview, darkPreview] {
            preview.navigationDelegate = self
            preview.loadFileURL(Template.url, allowingReadAccessTo: URL(fileURLWithPath: "/"))
        }
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: ThemeSettings.didChange, object: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    private static func makePreview(_ appearance: NSAppearance.Name) -> ViewerWebView {
        let view = ViewerWebView(frame: .zero, configuration: WKWebViewConfiguration())
        view.appearance = NSAppearance(named: appearance) // drives the page's prefers-color-scheme
        view.pageZoom = 0.85
        view.wantsLayer = true
        view.layer?.cornerRadius = 6
        view.layer?.masksToBounds = true
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.separatorColor.cgColor
        return view
    }

    private func configure(_ popup: NSPopUpButton, themes: [Theme], selected: Theme) {
        for theme in themes {
            popup.addItem(withTitle: theme.name)
            popup.lastItem?.representedObject = theme.id
        }
        popup.selectItem(withTitle: selected.name)
        popup.target = self
        popup.action = #selector(themeChosen(_:))
    }

    private func column(_ label: String, _ popup: NSPopUpButton, _ preview: NSView) -> NSView {
        let row = NSStackView(views: [NSTextField(labelWithString: label), popup])
        let stack = NSStackView(views: [row, preview])
        stack.orientation = .vertical
        stack.alignment = .leading
        preview.translatesAutoresizingMaskIntoConstraints = false
        preview.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        return stack
    }

    @objc private func themeChosen(_ sender: NSPopUpButton) {
        let id = sender.selectedItem?.representedObject as? String
        if sender === lightPopup {
            ThemeSettings.light = Theme.named(id, dark: false)
        } else {
            ThemeSettings.dark = Theme.named(id, dark: true)
        }
    }

    @objc private func themeDidChange() {
        for preview in [lightPreview, darkPreview] where loaded.contains(ObjectIdentifier(preview)) {
            preview.setTheme(ThemeSettings.css)
        }
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard let preview = webView as? ViewerWebView else { return }
        loaded.insert(ObjectIdentifier(preview))
        preview.setTheme(ThemeSettings.css)
        preview.callAsyncJavaScript(
            "mdv.update(html, '', '', '')",
            arguments: ["html": Markdown.render(Self.sample)],
            in: nil,
            in: .page,
            completionHandler: nil
        )
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // Only the initial shell load; the preview is static.
        decisionHandler(loaded.contains(ObjectIdentifier(webView)) ? .cancel : .allow)
    }
}

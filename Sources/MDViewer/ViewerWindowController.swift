import AppKit
import MDViewerCore
import WebKit

final class ViewerWindowController: NSWindowController, WKNavigationDelegate, NSSearchFieldDelegate {
    private let webView: ViewerWebView
    private let findBar = NSView()
    private let findField = NSSearchField()
    private var findBarHeight: NSLayoutConstraint!
    private var watcher: FileWatcher?
    private var shellLoaded = false
    private var pendingRender = false

    private var markdownDocument: MarkdownDocument? { document as? MarkdownDocument }

    init() {
        let config = WKWebViewConfiguration()
        config.suppressesIncrementalRendering = true
        webView = ViewerWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // no white flash in dark mode

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 1000),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.tabbingMode = .preferred
        window.minSize = NSSize(width: 320, height: 240)
        // Match the page theme so there's no flash while the page loads.
        window.backgroundColor = ThemeSettings.windowBackground
        super.init(window: window)

        window.setFrameAutosaveName("MDViewerWindow")
        if window.frame.origin == .zero { window.center() }

        buildLayout(in: window)
        webView.navigationDelegate = self
        webView.pageZoom = AppSettings.zoom
        webView.loadFileURL(Template.url, allowingReadAccessTo: URL(fileURLWithPath: "/"))

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: ThemeSettings.didChange, object: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override var document: AnyObject? {
        didSet {
            guard let doc = markdownDocument, let url = doc.fileURL else { return }
            watcher = FileWatcher(url: url) { [weak self] in
                guard let self, let doc = self.markdownDocument else { return }
                if doc.reloadFromDisk() { self.render() }
            }
            render()
        }
    }

    // MARK: Layout

    private func buildLayout(in window: NSWindow) {
        let container = NSView()
        window.contentView = container

        findField.placeholderString = "Find"
        findField.delegate = self
        findField.sendsSearchStringImmediately = false
        findField.sendsWholeSearchString = true
        findField.target = self
        findField.action = #selector(findFieldSubmitted(_:))

        let done = NSButton(title: "Done", target: self, action: #selector(hideFindBar(_:)))
        done.bezelStyle = .rounded
        done.controlSize = .small

        let separator = NSBox()
        separator.boxType = .separator

        for v in [findField, done, separator] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            findBar.addSubview(v)
        }
        findBar.translatesAutoresizingMaskIntoConstraints = false
        findBar.isHidden = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(findBar)
        container.addSubview(webView)

        findBarHeight = findBar.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            findBar.topAnchor.constraint(equalTo: container.safeAreaLayoutGuide.topAnchor),
            findBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            findBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            findBarHeight,

            findField.leadingAnchor.constraint(equalTo: findBar.leadingAnchor, constant: 10),
            findField.centerYAnchor.constraint(equalTo: findBar.centerYAnchor),
            findField.widthAnchor.constraint(equalToConstant: 260),
            done.leadingAnchor.constraint(equalTo: findField.trailingAnchor, constant: 8),
            done.centerYAnchor.constraint(equalTo: findBar.centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: findBar.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: findBar.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: findBar.bottomAnchor),

            webView.topAnchor.constraint(equalTo: findBar.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }

    // MARK: Rendering

    private func render() {
        guard shellLoaded else { pendingRender = true; return }
        guard let doc = markdownDocument, let url = doc.fileURL else { return }

        let html = Markdown.render(doc.text)
        let base = url.deletingLastPathComponent().absoluteString
        let args: [String: Any] = ["html": html, "base": base, "root": repoRoot?.absoluteString ?? "", "hash": ""]
        webView.callAsyncJavaScript(
            "mdv.update(html, base, root, hash)",
            arguments: args,
            in: nil,
            in: .page,
            completionHandler: nil
        )
    }

    private lazy var repoRoot: URL? = markdownDocument?.fileURL.flatMap {
        RepoRoot.find(from: $0.deletingLastPathComponent())
    }

    @objc private func themeDidChange() {
        window?.backgroundColor = ThemeSettings.windowBackground
        if shellLoaded { webView.setTheme(ThemeSettings.css) }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard !shellLoaded else { return }
        shellLoaded = true
        self.webView.setTheme(ThemeSettings.css) // in case it changed while the shell was loading
        if pendingRender || markdownDocument != nil {
            pendingRender = false
            render()
        }
    }

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard action.navigationType == .linkActivated, let url = action.request.url else {
            // Only the initial shell load is allowed to navigate the view.
            decisionHandler(shellLoaded ? .cancel : .allow)
            return
        }
        decisionHandler(.cancel)

        var target = url
        if url.isFileURL, !FileManager.default.fileExists(atPath: url.path), let root = repoRoot {
            // GitHub-style repo-root link, e.g. [docs](/docs/guide.md)
            target = root.appendingPathComponent(url.path)
        }

        if Markdown.isMarkdownFile(target) {
            // Link to another Markdown file: open it in this app.
            NSDocumentController.shared.openDocument(withContentsOf: target, display: true) { _, _, error in
                if let error { NSApp.presentError(error) }
            }
        } else {
            NSWorkspace.shared.open(target)
        }
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        shellLoaded = false
        webView.loadFileURL(Template.url, allowingReadAccessTo: URL(fileURLWithPath: "/"))
    }

    // MARK: Actions

    @objc func reloadDocument(_ sender: Any?) {
        if markdownDocument?.reloadFromDisk() == true { render() }
    }

    func printOperation(settings: [NSPrintInfo.AttributeKey: Any]) -> NSPrintOperation {
        let info = NSPrintInfo(dictionary: settings)
        // AppKit defaults to 1" margins on every side; half an inch reads better for text.
        info.topMargin = 36
        info.bottomMargin = 36
        info.leftMargin = 36
        info.rightMargin = 36
        let op = webView.printOperation(with: info)
        op.view?.frame = webView.bounds
        return op
    }

    func applyZoom(_ zoom: CGFloat) {
        webView.pageZoom = zoom
    }

    @objc func showFindBar(_ sender: Any?) {
        findBar.isHidden = false
        findBarHeight.constant = 36
        window?.makeFirstResponder(findField)
        findField.selectText(nil)
    }

    @objc func hideFindBar(_ sender: Any?) {
        findBar.isHidden = true
        findBarHeight.constant = 0
        window?.makeFirstResponder(webView)
    }

    @objc func findNext(_ sender: Any?) { find(backwards: false) }
    @objc func findPrevious(_ sender: Any?) { find(backwards: true) }

    @objc private func findFieldSubmitted(_ sender: NSSearchField) {
        let backwards = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
        find(backwards: backwards)
    }

    private func find(backwards: Bool) {
        if findBar.isHidden { showFindBar(nil) }
        let query = findField.stringValue
        guard !query.isEmpty else { return }
        let config = WKFindConfiguration()
        config.backwards = backwards
        config.caseSensitive = false
        config.wraps = true
        webView.find(query, configuration: config) { [weak self] result in
            if !result.matchFound { self?.findField.textColor = .systemRed } else { self?.findField.textColor = .labelColor }
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            hideFindBar(nil)
            return true
        }
        return false
    }
}

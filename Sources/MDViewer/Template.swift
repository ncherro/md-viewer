import Foundation

/// Builds the HTML shell (highlight.js and the current theme inlined) and writes
/// it to a cache file so WKWebView can load it as a file URL — which is what lets
/// relative image paths in the Markdown resolve against the document's folder.
/// Mermaid is too big to inline (~5 MB), so the page loads it from the bundle
/// only when a document has a diagram.
/// Rewritten only when the theme changes; open pages get new themes via `mdv.setTheme`.
enum Template {
    private static let source: String = {
        let res = Bundle.main.resourceURL!
        func read(_ name: String) -> String {
            (try? String(contentsOf: res.appendingPathComponent(name), encoding: .utf8)) ?? ""
        }
        return read("template.html")
            .replacingOccurrences(of: "/*HLJS_JS*/", with: read("highlight.min.js"))
            .replacingOccurrences(of: "/*MERMAID_URL*/", with: res.appendingPathComponent("mermaid.min.js").absoluteString)
    }()

    /// In Caches rather than the temp dir, which macOS purges of files older than a few days
    /// while the app is still running.
    private static let dir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        return caches.appendingPathComponent(Bundle.main.bundleIdentifier ?? "MDViewer", isDirectory: true)
    }()

    private static var file: URL { dir.appendingPathComponent("shell.html") }

    private static var writtenCSS: String?

    static var url: URL {
        let css = ThemeSettings.css
        // Caches can still be cleared (low disk space, cleanup apps), so check the file is there too.
        if css != writtenCSS || !FileManager.default.fileExists(atPath: file.path) {
            let html = source.replacingOccurrences(of: "/*THEME_CSS*/", with: css)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? html.write(to: file, atomically: true, encoding: .utf8)
            writtenCSS = css
        }
        return file
    }
}

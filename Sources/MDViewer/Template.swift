import Foundation

/// Builds the HTML shell once per launch (highlight.js inlined) and writes it
/// to a temp file so WKWebView can load it as a file URL — which is what lets
/// relative image paths in the Markdown resolve against the document's folder.
enum Template {
    static let url: URL = {
        let res = Bundle.main.resourceURL!
        func read(_ name: String) -> String {
            (try? String(contentsOf: res.appendingPathComponent(name), encoding: .utf8)) ?? ""
        }
        let html = read("template.html")
            .replacingOccurrences(of: "/*HLJS_JS*/", with: read("highlight.min.js"))

        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("MDViewer", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let out = dir.appendingPathComponent("shell.html")
        try? html.write(to: out, atomically: true, encoding: .utf8)
        return out
    }()
}

import Foundation
import cmark_gfm
import cmark_gfm_extensions

/// Renders GitHub-flavored Markdown to HTML using cmark-gfm (native C, very fast).
enum Markdown {
    private static let extensionNames = ["table", "strikethrough", "autolink", "tagfilter", "tasklist"]

    private static let registered: Void = {
        cmark_gfm_core_extensions_ensure_registered()
    }()

    static func render(_ source: String) -> String {
        _ = registered
        let (frontMatter, body) = splitFrontMatter(source)

        let options = CMARK_OPT_UNSAFE | CMARK_OPT_FOOTNOTES | CMARK_OPT_STRIKETHROUGH_DOUBLE_TILDE
        guard let parser = cmark_parser_new(options) else { return "" }
        defer { cmark_parser_free(parser) }

        for name in extensionNames {
            if let ext = cmark_find_syntax_extension(name) {
                cmark_parser_attach_syntax_extension(parser, ext)
            }
        }

        body.withCString { ptr in
            cmark_parser_feed(parser, ptr, strlen(ptr))
        }
        guard let doc = cmark_parser_finish(parser) else { return "" }
        defer { cmark_node_free(doc) }

        guard let cHTML = cmark_render_html(doc, options, cmark_parser_get_syntax_extensions(parser)) else { return "" }
        defer { free(cHTML) }
        let html = String(cString: cHTML)

        guard let frontMatter else { return html }
        return "<pre class=\"front-matter\"><code class=\"language-yaml\">\(escape(frontMatter))</code></pre>\n" + html
    }

    /// Pulls a leading YAML front-matter block (`---` … `---`) out so it doesn't render as an hr + heading.
    private static func splitFrontMatter(_ source: String) -> (String?, String) {
        guard source.hasPrefix("---\n") || source.hasPrefix("---\r\n") else { return (nil, source) }
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        for i in 1..<lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            if line == "---" || line == "..." {
                let fm = lines[1..<i].joined(separator: "\n")
                let rest = lines[(i + 1)...].joined(separator: "\n")
                return (fm, rest)
            }
        }
        return (nil, source)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}

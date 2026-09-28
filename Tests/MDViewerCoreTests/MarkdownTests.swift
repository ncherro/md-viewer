import Testing
@testable import MDViewerCore

@Suite struct MarkdownTests {
    @Test func headingsAndInlineFormatting() {
        let html = Fixtures.render("# Title\n\nSome **bold** and _italic_ and `code`.")
        #expect(html.contains("<h1>Title</h1>"))
        #expect(html.contains("<strong>bold</strong>"))
        #expect(html.contains("<em>italic</em>"))
        #expect(html.contains("<code>code</code>"))
    }

    @Test func tables() {
        let html = Fixtures.render("| A | B |\n|--:|---|\n| 1 | 2 |")
        #expect(html.contains("<table>"))
        #expect(html.contains("<th align=\"right\">A</th>"))
        #expect(html.contains("<td>2</td>"))
    }

    @Test func taskLists() {
        let html = Fixtures.render("- [x] done\n- [ ] todo")
        #expect(html.contains("<input type=\"checkbox\" checked=\"\" disabled=\"\" /> done"))
        #expect(html.contains("<input type=\"checkbox\" disabled=\"\" /> todo"))
    }

    @Test func strikethrough() {
        #expect(Fixtures.render("~~gone~~").contains("<del>gone</del>"))
    }

    @Test func bareURLsAreAutolinked() {
        let html = Fixtures.render("See https://example.com/page for more.")
        #expect(html.contains("<a href=\"https://example.com/page\">https://example.com/page</a>"))
    }

    @Test func footnotes() {
        let html = Fixtures.render("Claim.[^1]\n\n[^1]: Source.")
        #expect(html.contains("class=\"footnotes\""))
        #expect(html.contains("Source."))
    }

    @Test func fencedCodeKeepsLanguageClass() {
        let html = Fixtures.render("```swift\nlet x = 1\n```")
        #expect(html.contains("<pre><code class=\"language-swift\">let x = 1\n</code></pre>"))
    }

    @Test func rawHTMLIsAllowed() {
        let html = Fixtures.render("<img src=\"pic.png\" width=\"60\">")
        #expect(html.contains("<img src=\"pic.png\" width=\"60\">"))
    }

    @Test func scriptTagsAreFiltered() {
        // GFM's tagfilter extension neutralises dangerous tags, as on GitHub.
        let html = Fixtures.render("<script>alert(1)</script>")
        #expect(!html.contains("<script>"))
        #expect(html.contains("&lt;script>"))
    }

    // MARK: Front matter

    @Test func frontMatterRendersAsEscapedCodeBlock() {
        let html = Fixtures.render("---\ntitle: A <b> & C\n---\n# Body")
        #expect(html.hasPrefix("<pre class=\"front-matter\"><code class=\"language-yaml\">title: A &lt;b&gt; &amp; C</code></pre>"))
        #expect(html.contains("<h1>Body</h1>"))
        #expect(!html.contains("<hr />"))
    }

    @Test func frontMatterAcceptsDotsTerminator() {
        let html = Fixtures.render("---\na: 1\n...\ntext")
        #expect(html.contains("class=\"front-matter\""))
        #expect(html.contains("<p>text</p>"))
    }

    @Test func unterminatedFrontMatterRendersNormally() {
        let html = Fixtures.render("---\nnot closed")
        #expect(!html.contains("front-matter"))
        #expect(html.contains("<hr />"))
    }

    @Test func horizontalRuleLaterInDocumentIsNotFrontMatter() {
        let html = Fixtures.render("Intro\n\n---\n\nMore")
        #expect(!html.contains("front-matter"))
        #expect(html.contains("<hr />"))
    }

    @Test func emptyInput() {
        #expect(Fixtures.render("") == "")
    }
}

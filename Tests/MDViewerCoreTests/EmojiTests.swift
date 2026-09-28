import Testing
@testable import MDViewerCore

@Suite struct EmojiTableTests {
    let emoji = Fixtures.emoji

    @Test func bundledTableIsComplete() {
        #expect(emoji.count > 1500)
        #expect(emoji["tada"] == "🎉")
        #expect(emoji["+1"] == "👍")
        #expect(emoji["-1"] == "👎")
    }

    @Test func parsesTSV() {
        let table = EmojiTable(tsv: "a\t🅰️\nbad line\nb\t🅱️\n")
        #expect(table.count == 2)
        #expect(table["a"] == "🅰️")
    }

    @Test(arguments: [
        ("Ship it :rocket:", "Ship it 🚀"),
        (":+1: and :-1:", "👍 and 👎"),
        (":fire::fire:", "🔥🔥"),
        ("at 10:30 :coffee:", "at 10:30 ☕"),
        ("(:smile:)", "(😄)"),
        (":smile:.", "😄."),
        (":thumbsup:", "👍"),
    ])
    func replacesShortcodes(input: String, expected: String) {
        #expect(emoji.replaceShortcodes(in: input) == expected)
    }

    @Test(arguments: [
        "no colons here",
        ":notanemoji:",
        "a:b:c",            // :b: is a real shortcode, but it's glued to letters
        "word:smile:",
        ":smile:word",
        "::",
        ": smile :",
        "10:30",
        ":SMILE:",          // shortcodes are lowercase
    ])
    func leavesTextAlone(input: String) {
        #expect(emoji.replaceShortcodes(in: input) == nil)
    }
}

@Suite struct EmojiRenderingTests {
    @Test func replacedInTextHeadingsAndLinkText() {
        let html = Fixtures.render("# Release :tada:\n\n**Done :star:** [ship :ship:](https://x.com)")
        #expect(html.contains("<h1>Release 🎉</h1>"))
        #expect(html.contains("<strong>Done ⭐</strong>"))
        #expect(html.contains(">ship 🚢</a>"))
    }

    @Test func replacedInTables() {
        let html = Fixtures.render("| s |\n|---|\n| :white_check_mark: |")
        #expect(html.contains("<td>✅</td>"))
    }

    @Test func codeSpansAndBlocksAreUntouched() {
        let html = Fixtures.render("`:smile:`\n\n```\n:smile:\n```")
        #expect(html.contains("<code>:smile:</code>"))
        #expect(html.contains("<pre><code>:smile:\n</code></pre>"))
        #expect(!html.contains("😄"))
    }

    @Test func autolinkedURLsAreUntouched() {
        let html = Fixtures.render("https://example.com/:smile:/x and www.example.com/:smile:")
        #expect(!html.contains("😄"))
    }

    @Test func rawHTMLIsUntouched() {
        let html = Fixtures.render("<span title=\":smile:\">hi</span>")
        #expect(html.contains("title=\":smile:\""))
    }

    @Test func textSplitAroundColonsIsMerged() {
        // The autolink extension splits text nodes at ':'; shortcodes must still match.
        let html = Fixtures.render("see: foo :tada: bar")
        #expect(html.contains("see: foo 🎉 bar"))
    }
}

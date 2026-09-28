import Foundation
import MDViewerCore

/// Repo paths, resolved from this file's location so tests don't depend on the working directory.
enum Fixtures {
    static let repoRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent() // MDViewerCoreTests
        .deletingLastPathComponent() // Tests
        .deletingLastPathComponent()

    /// The real shortcode table shipped with the app.
    static let emoji: EmojiTable = {
        let url = repoRoot.appendingPathComponent("Resources/emoji.tsv")
        return EmojiTable(tsv: (try? String(contentsOf: url, encoding: .utf8)) ?? "")
    }()

    static func render(_ markdown: String) -> String {
        Markdown.render(markdown, emoji: emoji)
    }
}

/// A fresh temporary directory, removed when the returned closure runs.
func makeTempDir() throws -> URL {
    let dir = FileManager.default.temporaryDirectory
        .appendingPathComponent("MDViewerTests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.resolvingSymlinksInPath()
}

/// Polls `condition` on the main actor until it's true or `timeout` elapses.
@MainActor
func waitUntil(timeout: Duration = .seconds(3), _ condition: () -> Bool) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now + timeout
    while clock.now < deadline {
        if condition() { return true }
        try? await Task.sleep(for: .milliseconds(20))
    }
    return condition()
}

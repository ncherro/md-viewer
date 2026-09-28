import Foundation
import Testing
@testable import MDViewerCore

/// These exercise the save strategies real editors use. The watcher delivers on the
/// main queue, so the tests run on the main actor and poll while yielding it.
@Suite(.serialized) @MainActor
struct FileWatcherTests {
    private func setUp() throws -> (dir: URL, file: URL) {
        let dir = try makeTempDir()
        let file = dir.appendingPathComponent("doc.md")
        try "v1".write(to: file, atomically: false, encoding: .utf8)
        return (dir, file)
    }

    @Test func inPlaceWrite() async throws {
        let (dir, file) = try setUp()
        defer { try? FileManager.default.removeItem(at: dir) }
        var changes = 0
        let watcher = FileWatcher(url: file) { changes += 1 }

        let handle = try FileHandle(forWritingTo: file)
        handle.seekToEndOfFile()
        handle.write(Data(" appended".utf8))
        try handle.close()

        #expect(await waitUntil { changes >= 1 })
        _ = watcher
    }

    @Test func atomicSaveViaRename() async throws {
        // vim, VS Code, etc.: write a temp file, then rename it over the original.
        let (dir, file) = try setUp()
        defer { try? FileManager.default.removeItem(at: dir) }
        var changes = 0
        let watcher = FileWatcher(url: file) { changes += 1 }

        try "v2".write(to: file, atomically: true, encoding: .utf8)
        #expect(await waitUntil { changes >= 1 })

        // The original inode is gone; the watcher must have re-attached to the new file.
        let before = changes
        try await Task.sleep(for: .milliseconds(150))
        try "v3".write(to: file, atomically: true, encoding: .utf8)
        #expect(await waitUntil { changes > before })
        #expect(try String(contentsOf: file, encoding: .utf8) == "v3")
        _ = watcher
    }

    @Test func deleteThenRecreate() async throws {
        let (dir, file) = try setUp()
        defer { try? FileManager.default.removeItem(at: dir) }
        var changes = 0
        let watcher = FileWatcher(url: file) { changes += 1 }

        try FileManager.default.removeItem(at: file)
        #expect(await waitUntil { changes >= 1 })

        let before = changes
        try await Task.sleep(for: .milliseconds(300))
        try "back".write(to: file, atomically: false, encoding: .utf8)
        #expect(await waitUntil { changes > before })
        _ = watcher
    }

    @Test func burstOfWritesIsCoalesced() async throws {
        let (dir, file) = try setUp()
        defer { try? FileManager.default.removeItem(at: dir) }
        var changes = 0
        let watcher = FileWatcher(url: file) { changes += 1 }

        // Ten writes in quick succession, well inside the 50 ms debounce window.
        for i in 0..<10 {
            try "burst \(i)".write(to: file, atomically: false, encoding: .utf8)
        }
        #expect(await waitUntil { changes >= 1 })
        try await Task.sleep(for: .milliseconds(200))
        #expect(changes < 10)
        _ = watcher
    }

    @Test func stopsWatchingWhenReleased() async throws {
        let (dir, file) = try setUp()
        defer { try? FileManager.default.removeItem(at: dir) }
        var changes = 0
        var watcher: FileWatcher? = FileWatcher(url: file) { changes += 1 }
        _ = watcher
        watcher = nil

        try "after release".write(to: file, atomically: false, encoding: .utf8)
        try await Task.sleep(for: .milliseconds(300))
        #expect(changes == 0)
    }
}

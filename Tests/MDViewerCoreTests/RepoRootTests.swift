import Foundation
import Testing
@testable import MDViewerCore

@Suite struct RepoRootTests {
    @Test func findsGitDirectoryInAncestor() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root.appendingPathComponent(".git"), withIntermediateDirectories: true)
        let nested = root.appendingPathComponent("docs/guides", isDirectory: true)
        try FileManager.default.createDirectory(at: nested, withIntermediateDirectories: true)

        #expect(RepoRoot.find(from: nested)?.path == root.path)
        #expect(RepoRoot.find(from: root)?.path == root.path)
    }

    @Test func gitFileCountsForWorktreesAndSubmodules() throws {
        let root = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: root) }
        try "gitdir: /elsewhere".write(to: root.appendingPathComponent(".git"), atomically: true, encoding: .utf8)

        #expect(RepoRoot.find(from: root)?.path == root.path)
    }

    @Test func innermostRepoWins() throws {
        let outer = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: outer) }
        let inner = outer.appendingPathComponent("vendor/lib", isDirectory: true)
        try FileManager.default.createDirectory(at: outer.appendingPathComponent(".git"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: inner.appendingPathComponent(".git"), withIntermediateDirectories: true)

        #expect(RepoRoot.find(from: inner)?.path == inner.path)
    }

    @Test func nilOutsideAnyRepo() throws {
        let dir = try makeTempDir()
        defer { try? FileManager.default.removeItem(at: dir) }
        // The temp dir isn't inside a git repo on any normal machine.
        #expect(RepoRoot.find(from: dir) == nil)
    }
}

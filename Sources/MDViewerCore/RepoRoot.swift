import Foundation

public enum RepoRoot {
    /// The nearest enclosing git repository of `directory`, so `/path` links and images
    /// resolve from the repo root like on GitHub. `.git` may be a directory or (for
    /// worktrees and submodules) a file.
    public static func find(from directory: URL) -> URL? {
        var dir = directory.standardizedFileURL
        while dir.path != "/" {
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent(".git").path) { return dir }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }
}

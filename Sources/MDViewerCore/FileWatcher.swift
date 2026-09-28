import Foundation

/// Watches a single file for changes. Handles editors that save atomically
/// (write temp file + rename over the original), which replaces the inode and
/// would otherwise silently break a plain vnode watch.
public final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private var source: DispatchSourceFileSystemObject?
    private var pending: DispatchWorkItem?

    /// `onChange` is called on the main queue.
    public init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
        arm()
    }

    deinit { disarm() }

    private func arm(retries: Int = 50) {
        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else {
            // File is briefly missing mid-save; try again shortly.
            if retries > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.arm(retries: retries - 1)
                }
            }
            return
        }
        if retries < 50 {
            // The file reappeared after a gap; pick up its new contents.
            scheduleChange()
        }

        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .extend, .delete, .rename, .attrib, .link],
            queue: .main
        )
        src.setEventHandler { [weak self, weak src] in
            guard let self, let src else { return }
            let flags = src.data
            if !flags.isDisjoint(with: [.delete, .rename, .link]) {
                // Inode was replaced; re-attach to whatever now lives at the path.
                self.disarm()
                self.arm()
            }
            self.scheduleChange()
        }
        src.setCancelHandler { close(fd) }
        src.resume()
        source = src
    }

    private func disarm() {
        source?.cancel()
        source = nil
    }

    /// Coalesce bursts of events (editors often emit several per save).
    private func scheduleChange() {
        pending?.cancel()
        let item = DispatchWorkItem { [weak self] in self?.onChange() }
        pending = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05, execute: item)
    }
}

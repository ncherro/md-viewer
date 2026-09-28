import AppKit

/// A read-only Markdown document. NSDocument gives us Open, Open Recent,
/// one-window-per-file and window restoration for free; we never write.
@objc(MarkdownDocument)
final class MarkdownDocument: NSDocument {
    private(set) var text = ""

    override class var autosavesInPlace: Bool { false }
    override class func canConcurrentlyReadDocuments(ofType typeName: String) -> Bool { true }
    override func canAsynchronouslyWrite(to url: URL, ofType typeName: String, for saveOperation: NSDocument.SaveOperationType) -> Bool { false }

    override func read(from data: Data, ofType typeName: String) throws {
        text = String(decoding: data, as: UTF8.self)
    }

    override func data(ofType typeName: String) throws -> Data {
        throw CocoaError(.featureUnsupported)
    }

    override func makeWindowControllers() {
        addWindowController(ViewerWindowController())
    }

    override func printOperation(withSettings printSettings: [NSPrintInfo.AttributeKey: Any]) throws -> NSPrintOperation {
        guard let wc = windowControllers.first as? ViewerWindowController else { throw CocoaError(.featureUnsupported) }
        return wc.printOperation(settings: printSettings)
    }

    /// Re-read from disk; returns false if the file is unreadable (e.g. mid-save).
    @discardableResult
    func reloadFromDisk() -> Bool {
        guard let url = fileURL, let data = try? Data(contentsOf: url) else { return false }
        text = String(decoding: data, as: UTF8.self)
        return true
    }

    // We do our own file watching (see FileWatcher). Opt out of NSDocument's
    // file-presenter behaviour so an editor's "rename original to backup~, write new"
    // save strategy doesn't make us follow the file to its backup name, and so
    // we never show "file changed by another application" alerts.
    override func presentedItemDidMove(to newURL: URL) {}
    override func presentedItemDidChange() {}
}

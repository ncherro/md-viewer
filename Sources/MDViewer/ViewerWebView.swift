import AppKit
import MDViewerCore
import WebKit

/// The page view. Markdown files dropped on it open in the app (the same as
/// File → Open); any other drag is left to WebKit.
final class ViewerWebView: WKWebView {
    private func markdownURLs(_ info: NSDraggingInfo) -> [URL] {
        let urls = info.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] ?? []
        return urls.filter(Markdown.isMarkdownFile)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        markdownURLs(sender).isEmpty ? super.draggingEntered(sender) : .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        markdownURLs(sender).isEmpty ? super.draggingUpdated(sender) : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        if let sender, !markdownURLs(sender).isEmpty { return }
        super.draggingExited(sender)
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        markdownURLs(sender).isEmpty ? super.prepareForDragOperation(sender) : true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = markdownURLs(sender)
        guard !urls.isEmpty else { return super.performDragOperation(sender) }
        for url in urls {
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, error in
                if let error { NSApp.presentError(error) }
            }
        }
        return true
    }

    override func concludeDragOperation(_ sender: NSDraggingInfo?) {
        if let sender, !markdownURLs(sender).isEmpty { return }
        super.concludeDragOperation(sender)
    }

    func setTheme(_ css: String) {
        callAsyncJavaScript("mdv.setTheme(css)", arguments: ["css": css], in: nil, in: .page, completionHandler: nil)
    }
}

import AppKit
import UniformTypeIdentifiers

enum AppSettings {
    enum Appearance: Int { case system = 0, light, dark }

    static var appearance: Appearance {
        get { Appearance(rawValue: UserDefaults.standard.integer(forKey: "appearance")) ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "appearance") }
    }

    static var zoom: CGFloat {
        get {
            let z = UserDefaults.standard.double(forKey: "zoom")
            return z == 0 ? 1 : z
        }
        set { UserDefaults.standard.set(Double(newValue), forKey: "zoom") }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuItemValidation {
    static let markdownUTIs = ["net.daringfireball.markdown"]

    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = NSDocumentController.shared
        NSApp.mainMenu = MainMenu.build()
        applyAppearance()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Allow `MDViewer path/to/file.md` when the binary is invoked directly.
        for arg in CommandLine.arguments.dropFirst() where !arg.hasPrefix("-") {
            let url = URL(fileURLWithPath: arg).standardizedFileURL
            NSDocumentController.shared.openDocument(withContentsOf: url, display: true) { _, _, _ in }
        }
    }

    // Launched with no files (e.g. from Finder / Spotlight): show the Open panel.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool { true }

    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        NSDocumentController.shared.openDocument(nil)
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag { NSDocumentController.shared.openDocument(nil) }
        return false
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    // MARK: Appearance

    private func applyAppearance() {
        switch AppSettings.appearance {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    // Not named `setAppearance:` — NSApplication already implements that and sits
    // earlier in the responder chain, so it would receive the menu item as an appearance.
    @objc func chooseAppearance(_ sender: NSMenuItem) {
        AppSettings.appearance = AppSettings.Appearance(rawValue: sender.tag) ?? .system
        applyAppearance()
    }

    // MARK: Zoom (global, applies to all windows)

    @objc func increaseZoom(_ sender: Any?) { setZoom(AppSettings.zoom * 1.1) }
    @objc func decreaseZoom(_ sender: Any?) { setZoom(AppSettings.zoom / 1.1) }
    @objc func resetZoom(_ sender: Any?) { setZoom(1) }

    private func setZoom(_ z: CGFloat) {
        AppSettings.zoom = min(max(z, 0.5), 3)
        for doc in NSDocumentController.shared.documents {
            for wc in doc.windowControllers { (wc as? ViewerWindowController)?.applyZoom(AppSettings.zoom) }
        }
    }

    // MARK: Default handler

    @objc func makeDefaultViewer(_ sender: Any?) {
        AppDelegate.registerAsDefault()
        let alert = NSAlert()
        alert.messageText = "MD Viewer is now the default app for Markdown files."
        alert.informativeText = "`open file.md` will open files here."
        alert.runModal()
    }

    static func registerAsDefault() {
        guard let bundleID = Bundle.main.bundleIdentifier else { return }
        LSRegisterURL(Bundle.main.bundleURL as CFURL, true)
        for uti in markdownUTIs {
            LSSetDefaultRoleHandlerForContentType(uti as CFString, .viewer, bundleID as CFString)
            LSSetDefaultRoleHandlerForContentType(uti as CFString, .all, bundleID as CFString)
        }
    }

    func validateMenuItem(_ item: NSMenuItem) -> Bool {
        if item.action == #selector(chooseAppearance(_:)) {
            item.state = item.tag == AppSettings.appearance.rawValue ? .on : .off
        }
        return true
    }
}

import AppKit

enum MainMenu {
    static func build() -> NSMenu {
        let main = NSMenu()
        let appName = "MD Viewer"

        // App
        let app = submenu(appName, in: main)
        app.addItem(withTitle: "About \(appName)", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "Make Default Markdown Viewer", action: #selector(AppDelegate.makeDefaultViewer(_:)), keyEquivalent: "")
        app.addItem(.separator())
        let services = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        services.submenu = NSMenu(title: "Services")
        NSApp.servicesMenu = services.submenu
        app.addItem(services)
        app.addItem(.separator())
        app.addItem(withTitle: "Hide \(appName)", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        app.addItem(withTitle: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            .keyEquivalentModifierMask = [.command, .option]
        app.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        app.addItem(.separator())
        app.addItem(withTitle: "Quit \(appName)", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // File
        let file = submenu("File", in: main)
        file.addItem(withTitle: "Open…", action: #selector(NSDocumentController.openDocument(_:)), keyEquivalent: "o")
        let recent = NSMenuItem(title: "Open Recent", action: nil, keyEquivalent: "")
        let recentMenu = NSMenu(title: "Open Recent")
        // Lets AppKit's document controller populate this menu (what nib files do under the hood).
        let setMenuName = NSSelectorFromString("_setMenuName:")
        if recentMenu.responds(to: setMenuName) {
            recentMenu.perform(setMenuName, with: "_NSRecentDocumentsMenu")
        }
        recentMenu.addItem(withTitle: "Clear Menu", action: #selector(NSDocumentController.clearRecentDocuments(_:)), keyEquivalent: "")
        recent.submenu = recentMenu
        file.addItem(recent)
        file.addItem(.separator())
        file.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        file.addItem(withTitle: "Reload", action: #selector(ViewerWindowController.reloadDocument(_:)), keyEquivalent: "r")
        file.addItem(.separator())
        file.addItem(withTitle: "Print…", action: #selector(NSDocument.printDocument(_:)), keyEquivalent: "p")

        // Edit
        let edit = submenu("Edit", in: main)
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        edit.addItem(.separator())
        let find = NSMenuItem(title: "Find", action: nil, keyEquivalent: "")
        let findMenu = NSMenu(title: "Find")
        findMenu.addItem(withTitle: "Find…", action: #selector(ViewerWindowController.showFindBar(_:)), keyEquivalent: "f")
        findMenu.addItem(withTitle: "Find Next", action: #selector(ViewerWindowController.findNext(_:)), keyEquivalent: "g")
        findMenu.addItem(withTitle: "Find Previous", action: #selector(ViewerWindowController.findPrevious(_:)), keyEquivalent: "G")
        find.submenu = findMenu
        edit.addItem(find)

        // View
        let view = submenu("View", in: main)
        let appearance = NSMenuItem(title: "Appearance", action: nil, keyEquivalent: "")
        let appearanceMenu = NSMenu(title: "Appearance")
        for (title, tag, key) in [("System", 0, "0"), ("Light", 1, "1"), ("Dark", 2, "2")] {
            let item = appearanceMenu.addItem(withTitle: title, action: #selector(AppDelegate.chooseAppearance(_:)), keyEquivalent: key)
            item.keyEquivalentModifierMask = [.command, .shift]
            item.tag = tag
        }
        appearance.submenu = appearanceMenu
        view.addItem(appearance)
        view.addItem(.separator())
        view.addItem(withTitle: "Actual Size", action: #selector(AppDelegate.resetZoom(_:)), keyEquivalent: "0")
        view.addItem(withTitle: "Zoom In", action: #selector(AppDelegate.increaseZoom(_:)), keyEquivalent: "=")
        view.addItem(withTitle: "Zoom Out", action: #selector(AppDelegate.decreaseZoom(_:)), keyEquivalent: "-")
        view.addItem(.separator())
        view.addItem(withTitle: "Enter Full Screen", action: #selector(NSWindow.toggleFullScreen(_:)), keyEquivalent: "f")
            .keyEquivalentModifierMask = [.command, .control]

        // Window
        let window = submenu("Window", in: main)
        window.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        window.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        window.addItem(.separator())
        window.addItem(withTitle: "Bring All to Front", action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        NSApp.windowsMenu = window

        return main
    }

    private static func submenu(_ title: String, in main: NSMenu) -> NSMenu {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let menu = NSMenu(title: title)
        item.submenu = menu
        main.addItem(item)
        return menu
    }
}

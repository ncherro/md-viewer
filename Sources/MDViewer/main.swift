import AppKit

if CommandLine.arguments.contains("--make-default") {
    AppDelegate.registerAsDefault()
    exit(0)
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()

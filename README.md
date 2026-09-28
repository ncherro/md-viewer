# MD Viewer

A small, fast, read-only Markdown viewer for macOS.

- Native AppKit + WKWebView; Markdown parsed by [cmark-gfm](https://github.com/swiftlang/swift-cmark) (GitHub-flavored: tables, task lists, strikethrough, autolinks, footnotes)
- Light / dark / system appearance (View → Appearance, ⇧⌘0/1/2)
- Live reload when the file changes on disk (keeps scroll position; handles atomic saves)
- Syntax highlighting for fenced code blocks with a language (highlight.js, bundled offline)
- Relative images and links to other `.md` files work; find (⌘F), zoom (⌘+/⌘-/⌘0), print, Open Recent

## Build & install

Requires only the Xcode Command Line Tools.

```sh
./build.sh            # builds build/MD Viewer.app
./build.sh --install  # installs to ~/Applications and sets it as default for .md files
```

After installing, `open path/to/file.md` opens in MD Viewer. You can also re-assert the default
from the app menu → "Make Default Markdown Viewer".

To regenerate the app icon: `swift scripts/make-icon.swift`.

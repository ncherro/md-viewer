# MD Viewer

A small, fast, read-only Markdown viewer for macOS.

- Native AppKit + WKWebView; Markdown parsed by [cmark-gfm](https://github.com/swiftlang/swift-cmark) (GitHub-flavored: tables, task lists, strikethrough, autolinks, footnotes)
- Light / dark / system appearance — Rosé Pine Dawn (soft cream) and One Dark Pro themes
- Live reload when the file changes on disk (keeps scroll position; handles editors that save atomically)
- Syntax highlighting for fenced code blocks with a language (highlight.js, bundled — no network needed)
- GitHub-style emoji shortcodes (`:tada:` → 🎉, `:+1:` → 👍) using GitHub's own [gemoji](https://github.com/github/gemoji) list; left alone in code, URLs and words like `a:b:c`
- YAML front matter shown as a code block instead of rendering as a stray rule + heading
- Links to other `.md` files open in the viewer; web links open in your browser

## Build & install

Requires only the Xcode Command Line Tools (no Xcode).

```sh
./build.sh            # builds build/MD Viewer.app
./build.sh --install  # installs to ~/Applications and sets it as default for .md files
```

After installing, `open path/to/file.md` opens in MD Viewer. You can also re-assert the default
from the app menu → **Make Default Markdown Viewer**.

To regenerate the app icon: `swift scripts/make-icon.swift`.
To refresh the emoji list from GitHub: `scripts/update-emoji.sh`.

## Keyboard shortcuts

| Action                        | Shortcut        |
|-------------------------------|-----------------|
| Open                          | ⌘O              |
| Reload                        | ⌘R              |
| Find / next / previous        | ⌘F / ⌘G / ⇧⌘G   |
| Zoom in / out / actual size   | ⌘= / ⌘- / ⌘0    |
| Appearance: system/light/dark | ⇧⌘0 / ⇧⌘1 / ⇧⌘2 |
| Print                         | ⌘P              |

## Images

Local and GitHub-style image references are supported:

| Syntax                                           | Resolves to                                           |
|--------------------------------------------------|-------------------------------------------------------|
| `![](pic.png)`, `![](../assets/pic.png)`         | Relative to the Markdown file                         |
| `![](<my images/pic.png>)`, `my%20images/pic.png` | Paths with spaces                                     |
| `![](/assets/pic.png)`                           | The enclosing git repo's root (like GitHub), falling back to the absolute file path |
| `![](https://…)`                                 | Remote image                                          |
| `![](https://github.com/o/r/blob/main/pic.png)`  | Rewritten to the raw image, as GitHub does            |
| `<img src="pic.png" width="200">`                | Raw HTML is allowed                                   |
| `pic.png#gh-dark-mode-only` / `#gh-light-mode-only` | Shown only in the matching theme                   |
| `<picture><source media="(prefers-color-scheme: dark)" …>` | Follows the app's Light/Dark setting        |

Links like `[guide](/docs/guide.md)` resolve from the repo root the same way.

Notes: a `<picture>` block needs a blank line before it (same as on GitHub). Live reload
watches the Markdown file only — press ⌘R after replacing an image.

## Project layout

```
Sources/MDViewer/
  main.swift                   entry point (`--make-default` registers the app and exits)
  AppDelegate.swift            appearance, zoom, default-handler registration
  MainMenu.swift               menu bar (built in code, no nib)
  MarkdownDocument.swift       read-only NSDocument
  ViewerWindowController.swift web view, find bar, link handling, repo-root lookup
  FileWatcher.swift            live reload, survives atomic saves
  Markdown.swift               cmark-gfm rendering + front matter
  Emoji.swift                  :shortcode: → emoji
  Template.swift               builds the HTML shell once per launch
Resources/
  template.html                themes (CSS variables), styles and the page-side JS
  highlight.min.js             syntax highlighting (colors come from the theme in template.html)
  emoji.tsv                    shortcode table (from scripts/update-emoji.sh)
Info.plist                     bundle info + Markdown document type
build.sh                       build / install script
```

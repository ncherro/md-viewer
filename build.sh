#!/usr/bin/env bash
# Build "MD Viewer.app" into ./build. Pass --install to copy it to
# ~/Applications and make it the default handler for Markdown files.
set -euo pipefail
cd "$(dirname "$0")"

APP="build/MD Viewer.app"
swift build -c release
BIN="$(swift build -c release --show-bin-path)/MDViewer"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/MDViewer"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/template.html Resources/highlight.min.js Resources/hljs-light.css Resources/hljs-dark.css "$APP/Contents/Resources/"
[ -f Resources/AppIcon.icns ] && cp Resources/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP" 2>/dev/null
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
  DEST="$HOME/Applications/MD Viewer.app"
  mkdir -p "$HOME/Applications"
  osascript -e 'quit app id "com.ncherro.mdviewer"' 2>/dev/null || true
  rm -rf "$DEST"
  cp -R "$APP" "$DEST"
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"
  "$DEST/Contents/MacOS/MDViewer" --make-default
  echo "Installed to $DEST and set as default Markdown viewer"
fi

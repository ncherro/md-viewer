#!/usr/bin/env bash
# Runs the test suite. With only the Command Line Tools installed (no Xcode),
# Swift Testing ships in the CLT but isn't on SwiftPM's default search paths,
# so point the compiler, linker and loader at it.
set -euo pipefail
cd "$(dirname "$0")"

DEV_DIR="$(xcode-select -p)"
if [[ "$DEV_DIR" == *CommandLineTools* ]]; then
  LIB="$DEV_DIR/Library/Developer"
  exec swift test \
    -Xswiftc -F -Xswiftc "$LIB/Frameworks" \
    -Xlinker -F -Xlinker "$LIB/Frameworks" \
    -Xlinker -rpath -Xlinker "$LIB/Frameworks" \
    -Xlinker -rpath -Xlinker "$LIB/usr/lib" \
    "$@"
else
  exec swift test "$@"
fi

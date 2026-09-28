#!/usr/bin/env bash
# Regenerates Resources/emoji.tsv (shortcode<TAB>emoji) from GitHub's gemoji database.
set -euo pipefail
cd "$(dirname "$0")/.."
curl -sfL https://raw.githubusercontent.com/github/gemoji/master/db/emoji.json | python3 -c '
import json, sys
rows = {}
for e in json.load(sys.stdin):
    for alias in e["aliases"]:
        rows[alias] = e["emoji"]
for name in sorted(rows):
    print(f"{name}\t{rows[name]}")
' > Resources/emoji.tsv
echo "Wrote $(wc -l < Resources/emoji.tsv | tr -d " ") shortcodes to Resources/emoji.tsv"

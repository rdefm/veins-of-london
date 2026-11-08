#!/usr/bin/env bash
# Sets lossy WebP (compress/mode=1, quality 0.85) in .import files for event stills and large HQ backdrops.
# .import files are gitignored; re-run after a fresh clone, then re-import (godot --headless --import).
cd "$(dirname "$0")/.."
files=$(find assets/events -name '*.import'; ls assets/hq/*_external.png.import assets/hq/*_room*.png.import assets/hq/lab-bench-with-equipment_portrait.png.import)
for f in $files; do
  sed -i 's/^compress\/mode=.*/compress\/mode=1/; s/^compress\/lossy_quality=.*/compress\/lossy_quality=0.85/' "$f"
done
echo "$(echo "$files" | wc -w) import files set lossy"

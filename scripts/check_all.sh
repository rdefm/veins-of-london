#!/usr/bin/env bash
# Runs `godot --check-only` over every .gd file in the project.
# Exits non-zero if any file fails to parse. Does not use `set -e` in the
# main loop deliberately, so every file gets checked and every failure
# gets reported in one pass instead of stopping at the first one.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

if [ -x "$PROJECT_DIR/godot" ]; then
	GODOT_BIN="$PROJECT_DIR/godot"
elif command -v godot >/dev/null 2>&1; then
	GODOT_BIN="godot"
else
	echo "No godot binary found. Run scripts/setup_godot.sh first." >&2
	exit 1
fi

cd "$PROJECT_DIR"

fail=0
count=0
while IFS= read -r -d '' f; do
	count=$((count + 1))
	if ! "$GODOT_BIN" --headless --check-only --script "$f" 2>&1; then
		echo "FAILED: $f"
		fail=1
	fi
done < <(find . -name "*.gd" -not -path "./.godot-bin/*" -not -path "./.godot/*" -print0)

echo ""
echo "Checked $count file(s)."
if [ "$fail" -ne 0 ]; then
	echo "check_all: FAILED"
else
	echo "check_all: all clean"
fi
exit $fail

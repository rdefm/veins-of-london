#!/usr/bin/env bash
# Runs the headless test suite: tests/test_runner.gd discovers and runs
# every tests/test_*.gd file. Exits non-zero if any case failed.
set -euo pipefail

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
"$GODOT_BIN" --headless -s tests/test_runner.gd

#!/usr/bin/env bash
# Syntax-checks every .gd file in the project via scripts/check_runner.gd
# (a -s SceneTree script, so autoloads register normally -- see that file's
# header comment for why the old per-file `--check-only --script X` loop
# false-positived on every autoload-referencing file). Exits non-zero if
# any file fails to load.
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
"$GODOT_BIN" --headless -s scripts/check_runner.gd

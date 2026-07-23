#!/usr/bin/env bash
# Soak test for T14's acceptance criterion: the playthrough test (part of
# the full suite tests/test_runner.gd discovers) must pass 20 consecutive
# runs. Each run is a genuinely separate `godot --headless` invocation
# (not just an in-process seed loop), so this also catches any autoload
# state that doesn't reset cleanly between runs.
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

RUNS=20
fail=0
for i in $(seq 1 "$RUNS"); do
	echo "=== soak run $i/$RUNS ==="
	if ! "$GODOT_BIN" --headless -s tests/test_runner.gd; then
		echo "soak run $i FAILED"
		fail=1
	fi
done

echo ""
if [ "$fail" -ne 0 ]; then
	echo "soak: FAILED (not all $RUNS runs were green)"
else
	echo "soak: all $RUNS runs green"
fi
exit $fail

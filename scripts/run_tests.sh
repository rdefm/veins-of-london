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

# Fail fast: abort when SCRIPT ERROR lines pile up (poisoned run). Override with MAX_SCRIPT_ERRORS.
MAX_SCRIPT_ERRORS="${MAX_SCRIPT_ERRORS:-200}"
LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT

"$GODOT_BIN" --headless -s tests/test_runner.gd >"$LOG" 2>&1 &
GODOT_PID=$!
tail -f --pid="$GODOT_PID" "$LOG" &
TAIL_PID=$!

while kill -0 "$GODOT_PID" 2>/dev/null; do
	if [ "$(grep -c "SCRIPT ERROR" "$LOG" || true)" -gt "$MAX_SCRIPT_ERRORS" ]; then
		kill -9 "$GODOT_PID" 2>/dev/null || true
		sleep 0.5
		kill "$TAIL_PID" 2>/dev/null || true
		echo "ABORT: more than $MAX_SCRIPT_ERRORS SCRIPT ERRORs - poisoned run" >&2
		exit 1
	fi
	sleep 1
done

STATUS=0
wait "$GODOT_PID" || STATUS=$?
wait "$TAIL_PID" 2>/dev/null || true
exit "$STATUS"

#!/usr/bin/env bash
# Enforces CLAUDE.md's comment + CODEMAP policy:
#   1. No CODEMAP.md table row over CODEMAP_ROW_CAP characters.
#   2. No .gd comment line using history vocabulary (ticket numbers, "used
#      to", "no longer", "previously", "old X", "deleted", "removed",
#      "renamed") -- comments describe what the code does now, not its past.
#   3. No `*_CARD := <int>` constants or `while` loops on cardIndex in tests/.
# A file listed in lint_tokens_allowlist.txt is skipped by both checks; any
# violation in a non-allowlisted file fails the lint. Plain bash/grep/awk,
# no godot required -- one grep pass per check, filtered by a single awk
# pass (not a subprocess per matched line, which is what made an earlier
# version of this script take minutes instead of ~1s).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ALLOWLIST="$SCRIPT_DIR/lint_tokens_allowlist.txt"
CODEMAP_ROW_CAP=400
VOCAB_REGEX='#.*(ticket[[:space:]]+[0-9]+|used to|no longer|previously|\bold[[:space:]]+[a-zA-Z]|deleted|removed|renamed)'

cd "$PROJECT_DIR"

status=0

# --- 1. CODEMAP.md row-length cap ---
if ! grep -qxF "CODEMAP.md" "$ALLOWLIST"; then
	while IFS=: read -r line_no line; do
		len=${#line}
		if [ "$len" -gt "$CODEMAP_ROW_CAP" ]; then
			echo "CODEMAP.md:${line_no}: row exceeds ${CODEMAP_ROW_CAP}-char cap (${len} chars)"
			status=1
		fi
	done < <(grep -n '^|' CODEMAP.md | grep -Ev '^[0-9]+:\| *-+ *\|')
fi

# --- 2. GDScript comment history-vocabulary check ---
# Mirrors check_runner.gd's file set: skip dot-dirs, top-level addons/, and
# android/build (vendored/generated, never project source).
vocab_hits="$(grep -rniE "$VOCAB_REGEX" --include='*.gd' \
	--exclude-dir='.?*' --exclude-dir=addons --exclude-dir=android . || true)"

if [ -n "$vocab_hits" ]; then
	vocab_report="$(printf '%s\n' "$vocab_hits" | awk -F: -v allowlist="$ALLOWLIST" '
		BEGIN {
			while ((getline line < allowlist) > 0) {
				if (line != "") allowed[line] = 1
			}
		}
		{
			file = $1
			sub(/^\.\//, "", file)
			if (!(file in allowed)) {
				print file ":" $2 ": comment uses history vocabulary"
			}
		}
	')"
	if [ -n "$vocab_report" ]; then
		printf '%s\n' "$vocab_report"
		status=1
	fi
fi

# --- 3. Raw card-index guard in tests/ ---
# Tests address event cards by key and cap walk loops. Flags `*_CARD := <int>`
# constants and `while` loops conditioned on cardIndex. A tests/ file listed in
# the allowlist (with a "# reason" line above it) is skipped.
CARD_REGEX='(_CARD[A-Z0-9_]*[[:space:]]*(:=|:[[:space:]]*int[[:space:]]*=|=)[[:space:]]*[0-9]+)|(^[[:space:]]*while\b.*(cardIndex|card_index))'
card_hits="$(grep -rnE "$CARD_REGEX" --include='*.gd' tests || true)"
if [ -n "$card_hits" ]; then
	card_report="$(printf '%s\n' "$card_hits" | awk -F: -v allowlist="$ALLOWLIST" '
		BEGIN {
			while ((getline line < allowlist) > 0) {
				if (line != "") allowed[line] = 1
			}
		}
		{
			if (!($1 in allowed)) {
				print $1 ":" $2 ": raw card index (use card keys, cap walk loops)"
			}
		}
	')"
	if [ -n "$card_report" ]; then
		printf '%s\n' "$card_report"
		status=1
	fi
fi

# --- 4. No direct state_changed.emit() in systems/ ---
# Systems call EventBus.mark_changed() (coalesced); only EventBus flushes.
emit_hits="$(grep -rnE '^[^#]*state_changed\.emit\(' --include='*.gd' systems || true)"
if [ -n "$emit_hits" ]; then
	printf '%s
' "$emit_hits" | awk -F: '{print $1 ":" $2 ": direct state_changed.emit() (use EventBus.mark_changed())"}'
	status=1
fi

exit $status

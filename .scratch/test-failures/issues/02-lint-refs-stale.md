# 02 — Diagnose and fix stale lint_refs.json

**Status:** ready-for-agent

**What to build:** `lint_refs_file_is_fresh` fails: `res://tools/lint_refs.json` is stale. Regenerate with `godot --headless -s scripts/export_lint_refs.gd` and commit. Diagnose why it drifted (data change without regeneration) and, if cheap, make `check_all.sh` or the commit workflow catch it. Do this after ticket 01, since event data changes alter the refs.

**Blocked by:** 01

**Relevant files:** `tools/lint_refs.json`, `scripts/export_lint_refs.gd`, `scripts/check_all.sh`, `tests/test_events.gd`

- [ ] `lint_refs_file_is_fresh` passes

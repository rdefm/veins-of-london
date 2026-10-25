# 02 — Fix `lint_refs_file_is_fresh`

**What to build:** regenerating the lint refs file leaves the freshness test passing on Windows. Investigate why a regen (`godot --headless -s scripts/export_lint_refs.gd`) still fails the test and produces a ~629-line diff: line-ending churn (CRLF vs LF), a real content mismatch, or event content that was out of sync. Fix the cause (export, test, or `.gitattributes`), then commit the regenerated file.

**Blocked by:** 01 — Fix `james_dial_repair` event validation (the refs include event content).

**Relevant files:** `tests/test_event_content_lint.gd` (`lint_refs_file_is_fresh`, ~line 112), `scripts/export_lint_refs.gd`, `tools/lint_refs.json`, `.gitattributes`.

**Status:** ready-for-agent

- [ ] Root cause of the post-regen failure identified
- [ ] `lint_refs_file_is_fresh` passes after a fresh regen
- [ ] Regen diff contains only real content changes (no line-ending churn)

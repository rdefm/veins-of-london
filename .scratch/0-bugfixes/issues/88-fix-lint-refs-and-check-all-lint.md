# 88 — Fix `lint_refs_file_is_fresh` and the `check_all` lint warnings

**What to build:** Bring the lint-refs file and the token lint back to clean. `lint_refs_file_is_fresh` fails (stale generated file or a generator bug); `scripts/check_all.sh` reports a CODEMAP row over the 400-char cap and a history-vocabulary comment.

**Blocked by:** None — can start immediately.

**Relevant files:** `scripts/export_lint_refs.gd`, `scripts/lint_tokens.sh`, `scripts/lint_tokens_allowlist.txt`, `CODEMAP.md` (row near line 102), `tests/test_board_meetings.gd` (near line 231)

**Status:** ready-for-agent

- [ ] `lint_refs_file_is_fresh` passes
- [ ] CODEMAP row split under 400 chars (not allowlisted)
- [ ] Comment reworded to describe current behaviour (not allowlisted)
- [ ] `scripts/check_all.sh` prints no lint lines

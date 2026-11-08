# 06 — Contract: lint rejects state_changed.emit() in systems/

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** `lint_tokens.sh` fails when `systems/` contains `state_changed.emit()`, so new code goes through `mark_changed()`. Sweep for stragglers first.

**Blocked by:** 04 (migrate-emit-systems-a-m), 05 (migrate-emit-systems-n-z-autoload)

**Relevant files:** `scripts/lint_tokens.sh`, `scripts/lint_tokens_allowlist.txt` (do not add entries), `scripts/check_all.sh`; review §5.2

**Status:** ready-for-agent

- [ ] A planted `state_changed.emit()` in a `systems/` file makes the lint fail
- [ ] Lint passes on the real tree

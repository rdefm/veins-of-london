# 05 — Migrate state_changed.emit() to mark_changed(): systems N–Z, autoload, tests

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** Same swap for `systems/` files n–z (about 27 files) and `autoload/SaveManager.gd`, plus the 10 test files that emit `state_changed` directly (decide per file: `mark_changed()` + `flush_now()`, or leave if testing the raw signal).

**Blocked by:** 03 (eventbus-mark-changed)

**Relevant files:** `systems/[n-z]*.gd`, `autoload/SaveManager.gd`, `grep -rl "state_changed.emit" tests` (10 files); review §2.1

**Status:** ready-for-agent

- [ ] No `state_changed.emit()` left in `systems/[n-z]*.gd` or `autoload/` (except inside EventBus itself)
- [ ] Affected tests pass
- [ ] `scripts/check_all.sh` clean

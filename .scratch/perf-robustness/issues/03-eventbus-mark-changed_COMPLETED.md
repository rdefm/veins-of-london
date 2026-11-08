# 03 — EventBus mark_changed / flush_now (expand)

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** EventBus can coalesce redraw requests: `mark_changed()` sets a dirty flag and defers one `state_changed` emission; `flush_now()` emits synchronously if dirty. The `state_changed` signal and old direct `emit()` keep working, so nothing breaks yet. Screen refresh handlers ignore a flush when queued for deletion. `CONNECT_DEFERRED` is not used.

**Blocked by:** None — can start immediately

**Relevant files:** `autoload/EventBus.gd`, `tests/test_eventbus.gd`, `scenes/screens/*.gd` and `scenes/components/*.gd` refresh handlers (grep `state_changed.connect`); review §2.1

**Status:** ready-for-agent

- [ ] N `mark_changed()` calls in one frame → exactly one `state_changed`
- [ ] `flush_now()` emits synchronously when dirty and not otherwise
- [ ] Refresh handlers return early if `is_queued_for_deletion()`
- [ ] Existing tests pass unchanged; `scripts/check_all.sh` clean

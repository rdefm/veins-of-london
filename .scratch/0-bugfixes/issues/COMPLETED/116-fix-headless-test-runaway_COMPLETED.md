# 116 — Fix runaway/hanging headless test run

**What to build:** Using ticket 115's confirmed root cause, make
`scripts/run_tests.sh` finish end-to-end again without manual intervention.
Fix the actual mechanism found — if it turns out to be a pattern shared
across multiple off-tree screen tests (not just one file), fix the pattern
(e.g. a shared teardown/disconnect helper in `tests/test_base.gd` that every
off-tree `Screen.new(); screen._ready()` test can call), not just the one
symptom ticket 115 happened to point at first.

**Blocked by:** 115 (its written diagnosis is the input to this ticket's
approach).

**Status:** ready-for-human

- [x] `scripts/run_tests.sh` completes end-to-end without manual
      intervention or a timeout wrapper; note the resulting wall-clock time
      in the ticket
- [x] Fix addresses the root cause identified in ticket 115 — if systemic
      across off-tree screen tests, the fix covers the pattern, not just
      `tests/test_event_screen.gd`
- [x] No test coverage lost (case count before/after matches, modulo any
      cases legitimately restructured as part of the fix)
- [x] `scripts/check_all.sh` and the individual affected test files still
      pass after the fix

## Fix (2026-09-12)

Root cause per ticket 115: every off-tree `Screen.new(); screen._ready()`
test case leaves its screen permanently connected to an `EventBus` signal,
because `queue_free()` never runs synchronously on a node that was never
added to a live `SceneTree` — nothing ever flushes the deferred free or
severs the connection. Rather than patch each of the dozen+ affected test
files (`test_combat_screen.gd`, `test_modal_layer.gd`, `test_map_screen.gd`,
`test_hq_screen.gd`, `test_hq_dial.gd`, `test_hq_lab_bench.gd`,
`test_hq_floorplan.gd`, `test_hq_door.gd`, `test_guild_marketplace_screen.gd`,
`test_contacts_screen.gd`, `test_event_screen.gd`, and any other file
following the same convention — `test_nav_bar.gd`, `test_top_bar.gd`,
`test_notification_toast.gd`, `test_bag_drawer.gd`, `test_map_canvas.gd`,
the `test_phone_*` family, etc.) individually, the fix lives in one place:
`tests/test_base.gd`'s `run_case()` now snapshots every `EventBus` signal's
connections before calling the case, and after the case returns,
disconnects (and `queue_free()`s) any connection that's new — i.e. any
off-tree node the case built and abandoned, in any file, present or future,
with zero per-file plumbing required. Verified no test file relies on a
screen surviving across multiple `run_case` calls in the same file (all
build fresh per case), so nothing legitimate gets torn down early.

**Result:** `scripts/run_tests.sh` now completes in **~41s** (2268 passed,
1 failed — see below), down from 30+ minutes / non-terminating. Verified
with `scripts/diagnose_115_timing.gd`: per-file deltas stay flat/low
throughout the run instead of climbing (`test_cultivating.gd`, previously
203s, now sub-second; no file spikes).

**Pre-existing, unrelated failure found during verification:**
`test_col_a1_archie_pry.gd`'s `col_a1_archie_pry_debt_names_the_exact_amount_and_date`
fails both before and after this fix (confirmed against unmodified `HEAD`
via `git stash`) — not caused by, or in scope for, this ticket. Flagging
for a separate ticket rather than fixing here.

**Coverage check:** individually re-ran the affected off-tree screen test
files; case counts match ticket 115's leak table exactly (e.g.
`test_combat_screen.gd` 66/66 pass, `test_modal_layer.gd` 64/64,
`test_event_screen.gd` 15/15, `test_hq_screen.gd` 25/25,
`test_map_screen.gd` 41/41) — no cases were added, removed, or
restructured.

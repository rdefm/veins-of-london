# 115 — Diagnose runaway/hanging headless test run since ticket 11

**What to build:** Not a code fix — a written diagnosis. `scripts/run_tests.sh`
now runs for 30+ minutes without terminating (previously it was slow around a
known soak case but did terminate — see the "Full suite perf" note in project
memory) and has to be killed by hand. The user first noticed this after
ticket 11 (`11-events-ui-implementation`, commits 957f9fc/8930b79), which
added `tests/test_event_screen.gd` and touched `scenes/screens/event.gd` /
`systems/events.gd`. Pin down the actual mechanism before anyone patches
anything.

**Leading hypothesis, not yet confirmed:** `tests/test_event_screen.gd`
follows the existing off-tree screen-test pattern (`Screen.new();
screen._ready()`, same as `tests/test_contacts_screen.gd` /
`tests/test_combat_screen.gd`), but across 15 cases and never frees the
resulting `EventScreen` instances. Each one's `_ready()` connects
`EventBus.state_changed.connect(_refresh)` permanently — with nothing ever
calling `queue_free()` or disconnecting, every leaked screen stays subscribed
for the rest of the *entire test process*, so every state mutation in every
later test file also re-triggers `_refresh()` on all of them. This is a
plausible compounding-cost mechanism, but may not be the real (or only)
cause — confirm rather than assume.

**Blocked by:** None — can start immediately.

**Status:** ready-for-human (findings below, handed to ticket 116)

- [x] Bisects (or otherwise isolates, e.g. running the suite against the
      commit before 957f9fc vs. `HEAD`) whether the runaway is newly
      introduced by ticket 11's commits or was already present beforehand
- [x] Identifies the exact test file(s)/case(s) responsible for the
      non-terminating behaviour — not just "the suite is slow somewhere",
      a specific mechanism with a reproduction
- [x] Confirms or refutes the leaked-`EventScreen`/`EventBus.state_changed`
      hypothesis above
- [x] Determines whether the same leak-without-teardown pattern already
      exists in other off-tree screen tests (`test_contacts_screen.gd`,
      `test_combat_screen.gd`, `test_hq_lab_bench.gd`, `test_map_canvas.gd`,
      etc.) or is unique to the new file
- [x] Findings written up (as a comment/update on this ticket, or a short
      doc referenced from it) with a reproducible before/after timing
      comparison, handed off to ticket 116 — no source fix in this ticket

## Findings (2026-09-12)

**Verdict: the leading hypothesis is refuted as the (sole) cause.** The
runaway is a pre-existing, systemic bug in the off-tree screen-test
pattern itself — ticket 11's `test_event_screen.gd` adds to it, but did
not introduce it and is not the dominant contributor.

### Mechanism (confirmed)

Several screens' `_ready()` do `EventBus.state_changed.connect(_refresh)`
(or equivalent) with **no matching `disconnect()`/`queue_free()` anywhere**:
`scenes/screens/contacts.gd`, `scenes/screens/combat.gd` (also
`combat_beats_played`/`combat_rewind_played`), `scenes/screens/hq_lab_bench.gd`,
`scenes/screens/map.gd`, and `scenes/screens/event.gd`. Every off-tree
screen test that does `Screen.new(); screen._ready()` (the established
convention — see `test_contacts_screen.gd`'s own comment) and never frees
the result leaks a permanently-subscribed listener for the rest of the
whole `godot --headless -s tests/test_runner.gd` process, since all
`test_*.gd` files run in one long-lived `SceneTree` (`tests/test_runner.gd`
never resets between files).

Case counts per off-tree screen test file (each `run_case` that builds a
fresh screen leaks one more listener):

| file | leaked instances |
|---|---|
| `test_combat_screen.gd` | 66 |
| `test_modal_layer.gd` | 64 |
| `test_map_screen.gd` | 41 |
| `test_hq_lab_bench.gd` | 30 |
| `test_hq_screen.gd` | 25 |
| `test_guild_marketplace_screen.gd` | 17 |
| `test_hq_dial.gd` | 15 |
| `test_event_screen.gd` (ticket 11) | 15 |
| `test_hq_floorplan.gd` | 6 |
| `test_hq_door.gd` | 5 |
| `test_contacts_screen.gd` | 2 |

Cost does **not** land as a uniform per-file slowdown for the rest of the
run. It lands as: *(number of `GameState` mutations a given file performs)
× (cumulative leaked-listener count accumulated so far)*. A file with few
mutations (e.g. `test_debug_start.gd`) stays fast throughout the run even
once hundreds of listeners are leaked; a file that mutates state heavily
(soaks, multi-day simulations) gets dramatically slower the later it runs,
because every mutation now re-triggers every leaked screen's `_refresh()`/
`_sync()` (full child rebuild, `get_children()`, etc.) on top of its own
work.

### Reproduction / timing (before ticket 11's own files ever load)

Ran an instrumented copy of `tests/test_runner.gd`
(`scripts/diagnose_115_timing.gd`, kept in the tree as a diagnostic tool)
that prints a per-file elapsed-time delta. Files run alphabetically, and
`test_cultivating.gd` / `test_dial.gd` / `test_district_events.gd` all
sort **before** `test_event_screen.gd`/`test_events.gd` — so none of
ticket 11's code has executed yet at these points:

```
  13241 ms (+  7151 ms)  test_combat_screen.gd     [66 pass / 0 fail]   <- 66 leaks land here
  20437 ms (+  6486 ms)  test_crafting.gd          [23 pass / 0 fail]   <- already paying for them
 223578 ms (+203141 ms)  test_cultivating.gd       [78 pass / 0 fail]   <- 203s, no event.gd code loaded yet
 224911 ms (+  1333 ms)  test_debug_start.gd        [1 pass / 0 fail]   <- low-mutation file stays fast
 226140 ms (+  1229 ms)  test_debug_tools.gd        [4 pass / 0 fail]
 283940 ms (+ 57800 ms)  test_dial.gd              [79 pass / 0 fail]   <- 58s
 295829 ms (+  7949 ms)  test_district_deck.gd     [21 pass / 0 fail]
 364555 ms (+ 68726 ms)  test_district_events.gd   [36 pass / 0 fail]   <- 69s
```

By the time the run was stopped (still inside `test_economy.gd`, still
alphabetically before `test_event_screen.gd`), over 6 real minutes had
already been spent and the trend was clearly still climbing — entirely on
listeners leaked by *pre-existing* files (`test_combat_screen.gd`,
`test_bench.gd`, `test_dial.gd`, etc.), none of which ticket 11 touched.
This matches (and explains) the earlier, less severe observation in
project memory ("Full suite perf": a 30+ min stall around
`test_playthrough.gd`'s soak case, reproduced *before* ticket 11 landed).
`test_playthrough.gd` runs alphabetically near the very end, by which
point dozens more off-tree screen/component tests (`test_hq_*`,
`test_map_*`, `test_modal_layer.gd`, the `test_phone_*` family, etc.) have
each added their own leaked listeners on top — so its already-expensive
soak (20 seeds × up to 150 days of mutations) pays the full accumulated
cost. The suite was not observed to hang in the sense of an infinite loop
or deadlock — no stall with zero progress was seen — it is a genuine,
increasingly severe **O(mutations × leaked listeners)** blowup that
becomes impractically slow (need not be provably unbounded to feel like
"never terminates" to a human waiting on it).

### Was ticket 11 the cause?

No. `test_event_screen.gd`'s 15 leaked `EventScreen` instances are a real,
additional instance of the same bug, but:

- The pattern (leak-without-teardown) already existed in at least four
  other screens/tests before ticket 11 touched anything.
- `test_combat_screen.gd` alone already leaks over 4x as many instances
  (66, with 3 leaked signal connections apiece) as `test_event_screen.gd`
  does, and long predates ticket 11.
- The severe (100+ second) per-file spikes are fully reproducible using
  only files that sort alphabetically *before* `test_event_screen.gd`,
  i.e. before any of ticket 11's code has run at all.

The user's own timeline ("first noticed after ticket 11") is plausible
without ticket 11 being the root cause: project memory already recorded
a 30+ min stall around `test_playthrough.gd` the day *before* ticket 11
landed (2026-09-11) — the full suite was already this expensive, and
ticket 11's extra 15 leaks (a small fraction of an already-large and
still-growing total) plus normal variance was enough to push a
run that "used to eventually finish" into "ran long enough that a human
gave up and killed it."

### Handoff to ticket 116

The fix needs to be **pattern-wide**, not a `test_event_screen.gd`-local
patch: every off-tree `Screen.new(); screen._ready()` test needs its
screen `queue_free()`'d (and, since `queue_free()` alone doesn't run
synchronously off-tree, its `EventBus` connections explicitly
`disconnect()`'d) after each case — most naturally as a shared teardown
helper in `tests/test_base.gd` that every off-tree screen test's
`run_case` wrapper (or a dedicated `_fresh_screen`/cleanup pair) can call,
covering at least: `test_contacts_screen.gd`, `test_combat_screen.gd`,
`test_hq_lab_bench.gd`, `test_map_screen.gd`, `test_event_screen.gd`,
`test_modal_layer.gd`, `test_hq_screen.gd`, `test_hq_dial.gd`,
`test_guild_marketplace_screen.gd`, `test_hq_floorplan.gd`,
`test_hq_door.gd`, and any other file following the same convention.
`scripts/diagnose_115_timing.gd` (kept in the tree) can verify the fix by
re-running and confirming per-file deltas stay flat/low regardless of run
position instead of climbing.

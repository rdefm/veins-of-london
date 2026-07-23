# Known bugs — 2026-07-23

The perf hang (`docs/BUGHUNT-2026-07-17.md` §2) and the previous entries in
this file — lambda-closure test bugs in `test_eventbus.gd`/`test_nav.gd`/
`test_notify.gd`, and `SaveManager.gd` round-tripping ints as floats — are
now fixed. See `systems/events.gd`'s `advance()`/`rewind()`, the caution
note in `autoload/Snapshots.gd`, `autoload/SaveManager.gd`'s
`_restore_int_types()`, and the array-capture pattern in the three test
files.

Fixing SaveManager surfaced two more, unrelated, pre-existing failures —
neither caused by anything in that fix; both were just never reached
before because the perf hang always killed the test run first.

---

## 1. GameData's own JSON values are float-contaminated, one level up

**Failing cases:** `test_playthrough.gd::full_playthrough_tutorial_economy_ticks_and_save_roundtrip`,
`test_savemanager.gd::export_string_reimports_to_an_equal_state`.

**Root cause:** `data/constants.json`'s `contacts.archie.startRelation` /
`recruitThreshold` (and likely equivalent fields elsewhere in `data/*.json`)
load as floats — JSON has no int type — and `GameState._new_contacts_state()`
copies them straight into a *brand-new* game's state with no cast to `int`.
So `contacts.archie.relation` is `10.0`, not `10`, from the moment a new
game starts, no save involved. This is invisible in scalar comparisons
(Godot treats `10.0 != 10` as `false`), which is why `test_gamedata.gd`'s
spot-checks never caught it, but it breaks whole-state deep-equality
checks — exactly what these two playthrough/export tests do.

**Why it surfaced now:** the SaveManager fix (`_restore_int_types()`) now
correctly produces a clean `int` on the *round-tripped* copy of state.
That copy now differs from the never-saved original, which still carries
the float — a mismatch that only exists because one side of the
comparison got fixed and the other didn't.

**Fix direction (not applied yet):** cast the known-int fields
(`startRelation`, `recruitThreshold`, and any equivalents in other
`data/*.json` tables) either in `GameData._load_json()` right after
parsing, or at the point `GameState._new_contacts_state()` (and any other
`new_game_state()` helper reading from `GameData`) consumes them. Worth
checking whether other `GameData` tables have the same latent
contamination before picking one fix site — this may not be contacts-only.

---

## 2. `Rooms.process_vein_station()` — uncharged-vein cultivate never succeeds

**Failing case:** `test_rooms.gd::veinStation_cultivates_an_uncharged_vein`.

**Symptom:** the test sets `contacts.archie.cultivatingSkill = 5` (should
make success easy) and tries all 200 seeds `0..199`, calling
`Rooms.process_vein_station()` once per seed on a fresh level-1 vein with
`devBar: 2`. Every single seed fails to produce `devBar > 2` — 0/200, not
just an unlucky run. Reproduced twice, identical result both times.

**Not caused by anything touched in the SaveManager/perf-hang work** — no
changes landed in `systems/rooms.gd`, `systems/cultivating.gd`, or
`autoload/Rng.gd`. This is a pre-existing bug (or a stale test assumption)
that was simply never reached before, same as #1.

**Not yet diagnosed further** — needs a look at `Rooms.process_vein_station()`
and whatever cultivate-chance formula it delegates to, to see whether the
success chance is actually zero for this input (a real formula bug) or
whether the test's own setup doesn't match what the function expects (a
test bug, same family as the earlier lambda-closure issues but a
different root cause).

---

## Summary

| # | Issue | Status |
|---|---|---|
| 1 | `GameData`/`GameState` bake float-contaminated JSON values into a fresh game's `contacts` (and possibly elsewhere) | Diagnosed, not fixed — needs a decision on fix site |
| 2 | `Rooms.process_vein_station()` cultivate roll never succeeds in `test_rooms.gd`'s uncharged-vein case, 0/200 seeds | Diagnosed, not fixed — root cause (formula vs. test) not yet isolated |

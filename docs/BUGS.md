# Known bugs — 2026-07-24

All three issues below are now fixed. `scripts/run_tests.sh` is green:
178 passed, 0 failed.

The perf hang (`docs/BUGHUNT-2026-07-17.md` §2) and the previous entries in
this file — lambda-closure test bugs in `test_eventbus.gd`/`test_nav.gd`/
`test_notify.gd`, and `SaveManager.gd` round-tripping ints as floats — were
already fixed as of 2026-07-23. See `systems/events.gd`'s `advance()`/
`rewind()`, the caution note in `autoload/Snapshots.gd`,
`autoload/SaveManager.gd`'s `_restore_int_types()`, and the array-capture
pattern in the three test files.

---

## 1. GameData's own JSON values were float-contaminated, one level up

**Fixed in:** `autoload/GameData.gd`.

**Root cause:** `JSON.parse_string()` always returns numbers as `float` —
JSON has no int type — and several places copied that raw parsed value
straight into `GameState`'s pure state tree with no cast to `int`. This
wasn't contacts-only, as originally suspected; it turned out to be a
general `GameData` problem hitting at least four sites:

- `GameState._new_contacts_state()` — `contacts.*.relation` /
  `recruitThreshold` from `data/constants.json`.
- `systems/events.gd::_grant_vein()` — copies an event's vein template
  (`level`, `devBar`, `chargeBlocks`) verbatim. This one didn't just fail
  a comparison, it **crashed**: `Cultivating.recharge_veins()` does
  `GameData.VEIN_LEVELS[str(vein["level"])]`, and `str(1.0)` is `"1.0"`,
  not `"1"` — the key lookup threw `Invalid access to property or key
  '1.0'`.
- `systems/events.gd::_apply_add()` — the generic `add` effect op,
  confirmed contaminating `world.archieChatUnlockDay`.
- `systems/debug_start.gd` — `factions.guild.relation`, same pattern
  (latent, no failing test, but same bug).

**Fix:** normalize once at the JSON-parsing boundary. `GameData._load_json()`
now recursively converts any parsed float with zero fractional part to
`int` before returning (`GameData._normalize_numbers()`). This fixes all
four sites above (and any not-yet-found ones reading from `GameData`) in
one place, rather than casting at every consumption site piecemeal.
Verified safe against the current data — every genuinely-fractional field
(`baseSuccess: 0.35`, `raidBaseChance: 0.005`, etc.) is unaffected; nothing
in `data/*.json` is an intentionally-whole-number float (e.g. `1.0`) that
this would misclassify.

Deliberately **not** applied the same way to `SaveManager`'s save/load
round-trip — see #3 below, which is the same underlying JSON fact but
needs the opposite strategy.

## 2. `Rooms.process_vein_station()` cultivate roll — was a test bug, not a formula bug

**Fixed in:** `tests/test_rooms.gd`.

**Root cause:** the test's own fixture, not `Rooms.process_vein_station()`
or the cultivate-chance formula (both verified correct: skill 5 gives a
78% success chance, and rolls behaved exactly as expected). The test used
a level-1 vein (`devBarMax: 8`) with `devBar: 2` and `cultivatingSkill: 5`
(gain `1+5=6`). Every successful roll pushed `devBar` to exactly 8, which
met `devBarMax` and triggered `Cultivating.level_up_vein()` — which resets
`devBar` back to 0 as part of leveling up. That masked the very success
the test was trying to detect via `vein["devBar"] > 2`, so it looked like
0/200 successes when the roll was actually succeeding at roughly the
expected rate.

**Fix:** bumped the fixture vein to level 2 (`devBarMax: 16`), which
leaves headroom so a successful roll (`2 + 6 = 8`) no longer crosses the
level-up threshold. `devBar: 2`, `cultivatingSkill: 5`, and the expected
final value (`2 + (1 + 5) = 8`) are otherwise unchanged.

## 3. SaveManager's modal round-trip — a whitelist gap, not a design flaw

**Fixed in:** `autoload/SaveManager.gd`.

**Found while fixing #1** — with the contacts/vein noise gone,
`full_playthrough_tutorial_economy_ticks_and_save_roundtrip` still failed
on one field: `modal.data.earned`/`gross` came back as `150.0`/`300.0`
after a save/load round-trip, not `150`/`300`.

**Root cause:** `_restore_int_types()` is a deliberate, careful whitelist
(it explicitly protects two genuinely-float fields, `combat.evadeChance`
and `devicesInProgress[].progress`, from being coerced) — it just never
had an entry for `state.modal`, whose `data` shape is polymorphic
(depends on `modal.type`: `craft_result`, `cultivate_result`,
`sale_result`, `james_job_offer`/`_short`/`_complete`, each with different
int fields).

**Fix:** added `_restore_modal_int_types()`, a per-modal-type table in the
same explicit style as the rest of the file (matching
`_restore_combat_int_types()`'s precedent) — not a blanket conversion,
since this file already has two fields where "round whole-number float"
is a legitimate, real value.

# 08 — Rewind, Failsafe and the guard-kit rewind

**What to build:** Rewind in live fights restores the last decision point with that pick undone. The snapshot cap is 2: a second Rewind steps back one more pick, and across a round boundary it restores that round's pre-rolled plans. Each step costs one `rewind` consumable or one loaded Dial rewind cast, and is blocked with a reason when neither is available. Undone beats play in reverse as in the prototype.

Failsafe still auto-rewinds on player KO, and the guard-kit rewind still saves a guard, both under the new snapshot model. Fog and RNG streams never reroll on Rewind.

**Blocked by:** 03

**Relevant files:** `systems/combat.gd` (`combat_rewind`, `push_combat_snapshot`, `_restore_from_snapshot`, `_try_failsafe`, `_try_guard_rewind`); `systems/combat_prototype.gd` (rewind-to-last-pick); `autoload/Snapshots.gd`; `systems/dial.gd`; `scenes/screens/combat.gd`; `tests/test_combat.gd`; REFERENCE §3.7b, §3.9

**Status:** ready-for-agent

- [ ] Rewind spends a consumable or Dial cast, and is blocked with a reason with neither
- [ ] Rewind restores state including pre-rolled plans and fog marks
- [ ] Failsafe and guard-kit rewind fire on KO as specified

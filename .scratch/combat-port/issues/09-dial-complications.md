# 09 — Dial Complications as actions

**What to build:** The player's Dial casts work in the new engine: a cast takes one action at the current pause, leaves guard state unchanged, and appears on the timeline. Ally Dial casts become entries in the ally's committed plan (shown to the player). Single-target casts use the current selection; AoE casts hit every living enemy. Cast scaling by Dial level and cast XP are unchanged.

**Rewind returns Dial charges (R§3.7b Rewind, whole-state restore).** Dial state (`player.dial`, `contacts.<id>.dial`) lives outside `state.combat`, so the round snapshot doesn't hold it today. Every Rewind, Failsafe and ally rewind (`Combat._restore_round_snapshot()`, ticket 08) must also return the charges spent by player and ally Dial casts since the restored snapshot. The one exception is the Dial rewind cast that paid for the Rewind (`Combat.round_rewind()`'s fallback), which stays spent, including when a later Rewind restores an older snapshot. Decide with the human whether cast XP is also returned.

**Blocked by:** 03, 04

**Relevant files:** `systems/combat.gd` (`cast_complication`, `_ally_try_cast`, `_ally_dial_pool`, `_spend_dial_cast`); `systems/dial.gd`; `scenes/components/dial_widget.gd`; `scenes/components/combat_command_dock.gd`; `tests/test_dial_widget.gd`; `tests/test_combat.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] A player cast costs one action and keeps guard state (seeded test)
- [ ] Ally casts show in the ally's plan before the player's pick
- [ ] Dial widget works on the new screen
- [ ] A Rewind (and a Failsafe / ally-rewind save) returns the charges of every player and ally Dial cast since the restored snapshot (seeded test)
- [ ] A Dial rewind cast that paid for a Rewind stays spent, even after a second Rewind restores an older snapshot

# 09 — Dial Complications as actions

**What to build:** The player's Dial casts work in the new engine: a cast takes one action at the current pause, leaves guard state unchanged, and appears on the timeline. Ally Dial casts become entries in the ally's committed plan (shown to the player). Single-target casts use the current selection; AoE casts hit every living enemy. Cast scaling by Dial level and cast XP are unchanged.

**Blocked by:** 03, 04

**Relevant files:** `systems/combat.gd` (`cast_complication`, `_ally_try_cast`, `_ally_dial_pool`, `_spend_dial_cast`); `systems/dial.gd`; `scenes/components/dial_widget.gd`; `scenes/components/combat_command_dock.gd`; `tests/test_dial_widget.gd`; `tests/test_combat.gd`; REFERENCE §3.7b

**Status:** ready-for-agent

- [ ] A player cast costs one action and keeps guard state (seeded test)
- [ ] Ally casts show in the ally's plan before the player's pick
- [ ] Dial widget works on the new screen

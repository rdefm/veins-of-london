# 01 — Rewind tiers: depth by tier

**What to build:** An in-combat Rewind jumps the fight back by its unit's full tier depth: T1 one round, T2 two, T3 three, T4 four, T5 to the fight's start, before round 1's first action. The player doesn't choose the depth; the unit decides. One unit = one jump. Before tapping, the player can see how far a unit will take them. Source: `docs/story-restructure.md` "Features to build", item 1.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (`round_rewind`, `round_rewind_block_reason`, snapshot push/restore, Failsafe ~L946), `systems/combat_rounds.gd`, `systems/rewind.gd` (payment), `scenes/components/combat_command_dock.gd`, `data/recipes.json` (rewind magnitude row), `data/constants.json`. REFERENCE §3.7b "Rewind", §3.9 Snapshots & Rewind, recipe table (`rewind` row, `[0,2,2,2,2,2]`).

**Status:** ready-for-agent

- [ ] Snapshots are kept at each round boundary (as many as T4 needs) plus one fight-start frame taken before any round-1 action resolves, including enemy actions that come before the player's first pick.
- [ ] Spending a rewind unit of tier N restores the snapshot N rounds back (T5: the fight-start frame), clamped to the oldest available. Only the paying unit stays spent; all other restore rules are unchanged.
- [ ] Dial `rewind` Complication charges use the loaded unit's tier for depth.
- [ ] Failsafe, guard-kit/ally rewind, the bench Rewind and the time-block Rewind behave exactly as before (regression tests).
- [ ] The Rewind control shows the depth of the unit it will spend (e.g. "back 2 rounds", "to the start").
- [ ] The recipe magnitude row and REFERENCE §3.7b/§3.9 are updated to describe the new model.
- [ ] `tests/test_combat*.gd` cover each tier's depth, T5 undoing a round-1 enemy action, and clamping.

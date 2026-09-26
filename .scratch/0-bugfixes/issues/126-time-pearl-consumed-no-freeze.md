# 126 — Time Pearl used up, but enemies still act

**Status:** ready-for-agent

**Blocked by:** None. Can start immediately.

**What to build:** Diagnose, then fix. Playtest report: throwing a Time Pearl in combat sometimes does nothing. The human confirmed:
- the pearl **is used up**
- the throw line (`"You throw a time pearl. The air goes thick. Everything slows. (N turns)"`) **does show**
- **no** `"X is frozen — no turn."` line follows, and the enemies act normally
- it has happened in fights with 1 enemy and in fights with several

Expected per REFERENCE.md §3.7 ("Use Time Pearl" / "Frozen pool"): `frozenTurns = effectPower`, and every living enemy loses one turn per point, each loss logging an `enemy_frozen` beat.

Do the diagnosis first. Reproduce it in a headless test before changing anything. Then fix the root cause. The fix must not change the formula or freeze rules in REFERENCE.md. If the root cause turns out to be a rule question, STOP and ask the human.

**Hypotheses (unverified, start here):**
1. **The freeze drains before the player sees it.** REFERENCE.md §3.7a flags this: a pearl spends the player's queued turn, and `conclude_decision_point()` → `advance_to_next_decision()` runs the remaining enemy turns right away. At `effectPower` 1 (skills 1–2, `[0,1,1,2,2,3]`), one rotation uses up the whole pool. The frozen beats should still be emitted in that case. Check whether they reach the screen (`scenes/screens/combat.gd` `_play_beats`, `combat_stage.gd`), or whether the `enemy_frozen` beat kind gets dropped or has no animation.
2. **Stale `frozenSkipped`.** An enemy index left in `combat.frozenSkipped` makes `_enemy_turn()` (`systems/combat.gd:1132`) end the rotation instead of skipping that enemy, so the enemy attacks. Possible sources: an earlier freeze (Black Hole, or James's Dial cast at `combat.gd:1037`), a snapshot restore (`combat.gd:1736-1737`), or a KO in the middle of a rotation.
3. **Power is 0.** Check the N in the throw line. `Crafting.effect_power()` (`systems/crafting.gd:46`) reads the player's *current* `craftingSkill` plus the Bench refine tier. `effectPower[0]` is 0.
4. **The wrong combat path.** Contexts that don't go through `_enemy_turn()`. `enemy_attack()` (`combat.gd:1099`) is used for flee's parting shot. Also check that every combat context (raid, home raid, mugging, event raid, defend vein) uses the queue walker at `combat.gd:746`.

**Relevant files:**
- `systems/combat.gd`: `use_time_pearl()` :1268, `_enemy_turn()` :1123, `_end_freeze_rotation()` :1145, `_all_living_enemies_skipped()` ~:1153, queue walker `advance_to_next_decision()` ~:700-760, `prime_decision_point()` / `conclude_decision_point()` :777-797, snapshot :630 / restore :1736, ally Dial pearl :1037
- `systems/crafting.gd`: `effect_power()` :46, `_active_refine_tier()` :36
- `scenes/components/bag_drawer.gd`: `_on_use_time_pearl()` :225
- `scenes/screens/combat.gd`: `_play_beats()` ~:310, `_on_beat_played()`
- `scenes/components/combat_stage.gd`: frozen rendering :598, `effect_key == "timePearl"` :688
- `tests/test_combat.gd`, `tests/test_combat_screen.gd`
- REFERENCE.md §3.7 ("Use Time Pearl", "Frozen pool", ally-effect table), §3.7a (queue contract, and the "Flagged, not resolved here" item-timing note)

- [ ] A headless test reproduces the bug (pearl used up, throw beat present, no `enemy_frozen` beat, enemy attacks) in a 1-enemy and a multi-enemy fight, and fails before the fix.
- [ ] Root cause written up in `## Comments` on this ticket.
- [ ] Fix makes every pearl that is used up skip at least one enemy turn per point of power, with the `enemy_frozen` beat shown.
- [ ] If the cause is hypothesis 1 (a rule question, not a bug): no mechanic change. Ask the human instead.
- [ ] Existing freeze tests (Black Hole stacking, ally Dial pearl, `frozenSkipped` snapshot) still pass.
- [ ] Manual check for the human: throw a pearl in a 1-enemy and a 2+-enemy fight. Confirm "is frozen — no turn" shows and the enemy doesn't attack that turn.

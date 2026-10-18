# 19 — Vision doc and visuals notes: old-engine references

**What to build:** `docs/combat-animation-vision.md` still describes the deleted speed-queue engine in its analysis sections: `player_attack()` (`systems/combat.gd:298`) resolving a whole round, `focusedEnemyIndex`, the speed-sorted turn queue, a `{kind: "player_attack", …}` beat example, and line-number citations into `systems/combat.gd` that no longer hold. Update those passages to the round fight as it stands (`CombatRounds` resolves picks into beats; `CombatRoundsScreen` plays them through `CombatDirector`; targeting is screen view state per REFERENCE §3.7a Targeting), keeping the doc's art/animation direction untouched. Cite functions by name, not line number. Same pass over `data/combat_visuals.json`'s prose notes (`actionRule` cites `CombatScreen._THROW_BEAT_KINDS` and `_allies_act`/`_ally_turn`, which are gone; `purpose` says `scenes/screens/combat.gd` renders combat) and `tests/test_combat_director.gd`'s `"player_attack"` fixture beat kind.

Doc-only plus JSON comments; no behaviour change. Per the consult-on-design-docs rule, rewording that would change a design choice goes to the human, not into the doc.

**Blocked by:** 16 and 17 (both change what the pacing and telegraph passages should say)

**Relevant files:** `docs/combat-animation-vision.md` (§2.4 strip, §3 subject table, §4.2 Enemy telegraph, the analysis around lines 160–190, 530–550, 680–690 at time of writing); `data/combat_visuals.json` (`purpose`, `actionRule`, `effectRule` notes); `tests/test_combat_director.gd`; `scenes/screens/combat_rounds.gd` (`beat_cues()`, `_move_pose_cues()` — what actually plays a throw/attack now); `systems/combat_rounds.gd` (`_beat()`)

**Status:** ready-for-agent

- [ ] `grep -nE "player_attack|focusedEnemyIndex|turnCursor|project_queue|build_turn_queue|_THROW_BEAT_KINDS|_ally_turn"` clean in the vision doc, `data/combat_visuals.json` and director tests
- [ ] No line-number citations into `systems/combat.gd` remain in the vision doc
- [ ] `scripts/check_all.sh` clean (JSON still loads)

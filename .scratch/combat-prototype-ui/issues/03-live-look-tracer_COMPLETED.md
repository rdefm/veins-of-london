# 03 — Live-look tracer: stage + dock + playback

**What to build:** After Start, the Combat Prototype fight renders in the live combat layout instead of the plain cards. The setup card is unchanged.

- Upper region: the pixel combat stage with each combatant's sprite. Enemy archetypes map to a sprite template via a new `template` field per archetype in the prototype data: mugger → `mugger`, bruiser → `homeRaidRaider`, turtle → `veinGuard`, V2 archetypes same as their V1. Allies use `archie` then `james` (data, not code). Validated at boot.
- Lower region: the command dock in generic-rows mode. Rows are Guard, Strike, Feint, Stun, Lure, Leg it, then the player's two loadout items (name + tier, spent ones disabled). Each row is disabled with the system's block reason when invalid. No Dial.
- Targeting: tap an enemy sprite (or a self/ally sprite for heals) to choose the target, as in live combat. The selected sprite gets the arrow. A sensible default target is preselected.
- At each player pause, picking a row resolves that action. The resulting beats play through the combat director: attack pose for Strike/Stun, hit recoil, damage numbers, shake, KO fall. The dock is locked during playback.
- Fight end: outcome message + New fight (back to setup), as now.
- A "Readouts" button toggles a window with the old text views: per-combatant HP, guard preview, statuses (Exposed, frozen, stunned, shield, powder, lady, sight), loadouts and the beat log by round. Rewind and Exit stay reachable.
- The screen keeps zero state mutation: it adapts prototype state into what the components need and calls only CombatPrototype functions.

**Blocked by:** 01, 02.

**Relevant files:** `scenes/screens/combat_prototype.gd`, `scenes/components/combat_stage.gd`, `scenes/components/combat_command_dock.gd`, `scenes/components/combat_director.gd`, `scenes/screens/combat.gd` (orchestration reference: `_play_beats`, `_on_beat_played`, `_select_target`), `systems/combat_prototype.gd` (read-only helpers), `data/combat_prototype.json`, `data/combat_visuals.json` (`templates`), `autoload/GameData.gd` (COMBAT_PROTOTYPE validation, `combat_templates()`), `tests/test_combat_prototype_screen.gd`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Archetype `template` field present and validated (unknown template → boot error).
- [ ] Screen test: Start builds the stage with one slot per living combatant and the dock rows above; a pick resolves via CombatPrototype and state changes only through it.
- [ ] Screen test: rows disabled per block reason; Readouts window toggles.
- [ ] Full fight playable headless through the screen's handlers to an outcome.
- [ ] On-device QA list in the report (sprites, targeting arrow, playback, readouts window).

# 07 — Move levels: progression + display

**What to build:** Every combatant has a level (1–5) for each move — Strike, Guard, Feint, Stun, Leg it — sitting alongside Combat Skill.
- **Player and every recruited contact** (Archie, James, other recruits) hold persistent per-move level + XP, starting at L1. Each resolved use of a move gives 10 XP; a fizzled use gives 4. Cumulative XP thresholds for L2/3/4/5: 30 / 90 / 200 / 400. XP lands as the action resolves; Rewind does **not** undo it.
- **Enemies and template allies** (Hired Guard, Firm muscle) roll fixed random move levels each fight: per move, their combat level 50%, one below 30%, two below 20%, minimum 1. Seeded from the fight RNG.
- **Level-up** posts a Notification and a transcript line.
- **Display:** move levels on the Profile skills card and in the Gym; a small level badge on each move in the Fight list.
- No stat effects in this ticket (08, 09) — levels exist and grow only.
All numbers in `data/combat_rounds.json`.

**Blocked by:** 01 — Merge Lure into Feint; 04 — Combat layout: board hidden + transcript; 05 — Command grid: Fight / Item / Dial / Leg it

**Relevant files:**
- `systems/combat_rounds.gd` (combatant build, action resolution, fizzle paths, Rewind snapshot — XP must live outside the snapshot)
- `systems/combat.gd` (player/ally combatant creation, `exit_combat`)
- `systems/contacts.gd` (contact state)
- `systems/notify.gd`
- `autoload/GameState.gd` (initial state), `autoload/SaveManager.gd` (backfill), `autoload/GameData.gd` (validation)
- `scenes/phone_apps/profile_app.gd`, `scenes/modals/hq_gym_modal.gd`, `scenes/components/combat_command_dock.gd`
- `data/combat_rounds.json`
- `tests/test_combat_rounds.gd`, `tests/test_combat.gd`, `tests/test_save*.gd`
- REFERENCE §2 (state paths), §3.7a Squad/Combat Skill, §3.7b XP and Table 3
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] New state paths documented in REFERENCE §2; old saves backfill all moves to L1 / 0 XP
- [ ] Resolved use +10 XP, fizzled +4, per move per combatant (player + recruits); level-ups at the thresholds; cap 5
- [ ] Rewind after XP gain keeps the XP (test)
- [ ] Enemy/template-ally move levels follow the weighted roll (seeded distribution test)
- [ ] Level-up emits one Notification + one transcript line
- [ ] Profile, Gym and Fight-list badge show current levels
- [ ] Human check: badge legibility in the Fight list; Profile/Gym cards

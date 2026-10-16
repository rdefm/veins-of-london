# 07 — Fog of war: unreliable reads

**What to build:** The player can't always read what an enemy will do. Some enemy intents are hidden as `?`.

- When enemy plans are committed for a round, each enemy action is rolled as **read** (shown as now) or **unread** (shown as `?`). An unread intent never lies. It only hides the move (and target/damage).
- Unread chance comes from data: a base curve by the player's Combat Skill (falls as it rises), plus a modifier per level the enemy is above the player (rises with the gap; draft: none or a small reduction when the enemy is lower).
- Prophet's Breath sight makes every read perfect (all intents shown, plus its target/damage/next-round reveal). Next-round intents under sight are also fully read.
- An unread intent is revealed when its action resolves.
- The fog roll is seeded and stored in prototype state, so it survives Rewind unchanged (no reroll by rewinding).
- Ally plans are always fully visible to the player.
- Ally AI and the sim's reader policy plan from the fogged view, not the truth. `?` = treat as unknown. Sim policies may hedge (e.g. guard), but must not peek at truth.
- Strip cards show `?` intents distinctly. The readouts window labels them unread.
- Sim gains a fog on/off switch and reports both, so the cost of fog is measurable.
- Draft curve values flagged in the report for tuning.

**Blocked by:** 02, 04.

**Relevant files:** `systems/combat_prototype.gd` (enemy plan roll, `enemy_intents`, `has_sight`, ally AI planning), `data/combat_prototype.json`, `autoload/GameData.gd` (validation), `tests/test_combat_prototype.gd`, `tests/test_combat_prototype_screen.gd`, `scripts/sim_combat_prototype_impl.gd`, `scenes/components/turn_order_strip.gd`, `scenes/screens/combat_prototype.gd`, `.scratch/combat-revamp/spec.md` (record fog rules), `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Test: with a forced unread roll, the screen-facing intents hide move/target/damage; the action still resolves as committed and is revealed after.
- [ ] Test: higher player Combat Skill lowers the unread rate over a seeded sample; a bigger enemy level gap raises it.
- [ ] Test: with sight active, nothing is unread (this round and next).
- [ ] Test: Rewind keeps the same read/unread rolls.
- [ ] Test: ally AI never acts on a truth it can't see (an unread enemy Strike doesn't trigger its targeted Guard rule).
- [ ] Sim runs both fog modes headless and prints both tables.
- [ ] Data validated at boot; draft values listed in the report.
- [ ] `PROSE-REVIEW:` on any new intent/readout strings.

# 19d — Enemies use Stutter and Invisibility

**What to build:** Raiders and other kit-carrying enemies can use Stutter and Invisibility against the player, and the player side reacts correctly to an invisible enemy.

- **Raid kits:** Firm and Guild `raidKits` get a small quota (placeholder) of each, drawn from faction holdings like the existing kit items.
- **Enemy AI rule order** (when swapping a planned Strike for a kit item):
  1. heal
  2. Shield
  3. Invisibility on itself when below 50% hp (threshold in data)
  4. Stutter in place of a Strike when its target isn't Guarded
  5. Blast
  - Still at most one kit item per enemy per round.
- **Player side vs an invisible enemy:**
  - The player can't pick it as the target of a Strike, Stun or single-target item. The blocked action shows a reason via the existing block-reason path.
  - Area items still hit it.
  - Its sprite is drawn at the same partial transparency as an invisible player.
- **Ally AI:** allies never target an invisible enemy. If every enemy is invisible, they Guard.
- **Visuals:** enemy uses of both items use the enemy palette shift, like other enemy-used items. Stutter's blink sequence plays on the enemy.

**Blocked by:** 19b, 19c

**Relevant files:**
- Data: `data/factions.json` (`raidKits`), `data/combat_rounds.json` (AI thresholds), `data/combat_visuals.json` (`enemyPalette`).
- Systems: `systems/faction_sim.gd` (`raider_kit`), `systems/combat_rounds.gd` (`_commit_kit_item`, ally planning, `_pick_block_reason`), `systems/combat.gd` (`_enemy_try_item`).
- Scenes: `scenes/screens/combat_rounds.gd`, `scenes/components/combat_stage.gd`.
- Tests: `tests/test_combat_rounds.gd`, `tests/test_combat.gd`.
- Docs: `CODEMAP.md`; REFERENCE §1.8 `data/factions.json`, §3.7b.

**Status:** ready-for-agent

- [ ] A Firm/Guild raid can field enemies carrying Stutter and Invisibility
- [ ] AI rule order tested: an enemy below the hp threshold turns invisible; one facing an unguarded target Stutters; earlier rules still win
- [ ] Player can't target an invisible enemy with Strike/Stun/single-target items (block reason shown); area items still hit it
- [ ] Allies skip invisible enemies and Guard when all are invisible
- [ ] Enemy uses render with the enemy palette; Stutter blink plays on enemies
- [ ] Rewind correct across an enemy's item use
- [ ] Numbers tagged for balance; REFERENCE §1.8/§3.7b and CODEMAP updated
- [ ] Human on-device check: invisible enemy visuals, greyed targeting, enemy Stutter blink

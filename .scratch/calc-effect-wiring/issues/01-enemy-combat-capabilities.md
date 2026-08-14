# 01 — Enemy combat capabilities: equipment, abilities, evade

**What to build:** Enemies currently have no equipment or ability concept at all — `data/enemies.json` and the procedural mugger generator are flat `hp`/`attackMin`/`attackMax` only (checked against `combat.gd` and REFERENCE.md §3.7). This ticket gives enemies a minimal capability surface: an enemy can optionally carry one weapon (an attack bonus) and/or one gated ability, and every enemy gets an evade-chance stat that gates whether the player's attack lands. This is foundation work with no new player-facing item — it exists so Blast's disarm (ticket 02) and a future Be a Lady spec have something real to act on, and so enemy combat has room to grow more interesting later (per the human's own framing during design).

**Blocked by:** None — can start immediately.

- [ ] Enemy dict shape gains an optional `weapon` (attack-bonus value) and an optional `ability` (identifier + any gating state, e.g. "usable once per fight" or "usable every N turns" — keep this minimal, not a full ability-effect system; just enough state that "the enemy's ability is locked out" is a real, checkable condition).
- [ ] Enemy dict gains an `evadeChance` stat. **Player attack resolution now rolls against it** — `chance(enemy.evadeChance)` → the enemy dodges (no damage, log line), same shape as the existing enemy-side `evadeTurns`/`evadeChance` check in `combat.gd:234` but mirrored for the player's own attacks.
- [ ] `evadeChance` defaults to **0%** on every *existing* enemy template (`raidGuards.*`, `homeRaidRaider`, and the procedural mugger generator) — preserves current combat math and existing test assertions unchanged.
- [ ] New default going forward for any newly-authored enemy template: **20% evade chance**, unless a specific template overrides it. Document this default where enemy templates are defined.
- [ ] A "strip weapon + lock ability for N turns" operation exists as a callable (e.g. `Combat.disarm_enemy(enemy, turns)`), for ticket 02's Blast to call — this ticket does not need to wire anything into a player-facing consumable itself, just make the operation real and tested.
- [ ] `tests/test_combat.gd` extended: player-attack evade roll (miss vs. hit, 0% and nonzero cases), disarm operation (weapon bonus removed, ability locked, expires after N turns), existing enemy templates unaffected (still 0% evade, existing damage-math tests green).
- [ ] Syntax check clean on all touched `.gd` files.

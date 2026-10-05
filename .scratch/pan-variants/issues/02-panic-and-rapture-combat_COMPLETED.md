# 02 — Combat: Panic and Pan's Rapture

**What to build:** Single-target, 2-turn statuses. Panic: each affected turn, independently and randomly, the target either cowers (loses its turn) or runs off; running off counts as defeated — same XP and win as a kill. Pan's Rapture: target blissfully ignores enemies and doesn't attack for its duration. Usable from the combat item UI.

**Blocked by:** 01 — Replace Pan's Prank recipes; `item-tiers` 04 — Per-tier item effects.

**Relevant files:** `systems/combat.gd` (turn order, enemy turn, `frozenTurns`/ability-lock bookkeeping ~line 1529, outcome handling), `systems/combat_prototype.gd`, `data/recipes.json`, `docs/combat-animation-vision.md`, REFERENCE §3.7/§3.7a, combat tests under `tests/`. Statuses live in pure-data combat state.

**Status:** ready-for-agent

- [ ] Panic per-turn random cower/flee; flee = defeated, win condition and XP intact
- [ ] Rapture target skips attacking for duration
- [ ] Tier effect reads from item tier (per approved table)
- [ ] Logged beats/prose flagged PROSE-REVIEW; tests with seeded RNG

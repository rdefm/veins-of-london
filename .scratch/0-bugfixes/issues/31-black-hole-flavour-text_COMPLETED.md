# 31 — Black Hole flavour text wrongly implies it hits the deployer

**What to build:** `blackHole`'s description in `data/recipes.json` reads "...Everything nearby gets pulled toward the middle, including the person who deployed it." Mechanics are already correct — `Combat.use_black_hole()` (`systems/combat.gd`) only damages the enemy and freezes the enemy's turn via `frozenTurns`; the player is never affected. Fix the text only.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `data/recipes.json`'s `blackHole.description` no longer implies the deployer is affected (PROSE-REVIEW: new/edited line, tone per `docs/CONTENT-GUIDE.md`).
- [ ] Confirm via `systems/combat.gd::use_black_hole()`/`player_attack()`/`enemy_attack()` that no code path applies damage or `frozenTurns` to the player when Black Hole is deployed (expected: already correct, verify not "fix").
- [ ] Existing combat tests still pass; add one asserting Black Hole never reduces player HP or freezes the player's turn.

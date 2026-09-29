# 07 — Guard kit pool in the fight

**What to build:** Guards in a vein defend fight use the vein's kit. At fight start the active kit is copied to `combat.guardKit = {items, used}`, a shared pool spent highest tier first, where each spend moves 1 unit from `items` to `used`. Item power is `effectPower[max(tier, 1)]`. On a guard's turn, the first rule that applies uses one item instead of attacking:
1. healingBurst: heals the most hurt of the player and living allies below 0.4.
2. prophetsBreath: gives the player evade when they're below 0.4 with no evade active.
3. shield: shields the most hurt of the player and guard allies with `shieldPool` 0.
4. blackHole: damages one enemy and freezes, when 2+ enemies are alive and none are frozen.
5. timePearl: freezes, on the same trigger as blackHole.
6. blast: hits the living enemy with the lowest hp.

Failsafe is automatic and saves a guard from a KO once, at 1 hp. The player's item menu reads only `player.inventory`. `exit_combat` takes `used` off `vein.guardKit` on a win, loss or flee. Rewind never refunds kit units. Rewind and Enhancement Powder rules are ticket 08.

**Blocked by:** 06 — Guards join the vein defend fight.

**Relevant files:** `systems/combat.gd` (`_ally_try_cast` ~1054 for the ally heal/pearl beats, raider kit precedent `_enemy_try_item`/`_spend_raider_item` ~1192–1260, player item effects `use_*` ~1400–1700, `ALLY_HEAL_THRESHOLD_FRACTION`, `exit_combat` ~1973), `systems/guard_kit.gd`, `tests/test_combat.gd`. Spec §Defend fight + §Decisions (tier 0). REFERENCE.md §3.7/§3.7a (Raider kits).

**Status:** ready-for-agent

- [ ] With a seeded Rng, each rule fires on its trigger and spends the highest tier first. A tier-0 unit powers as tier 1.
- [ ] Failsafe saves a guard once per unit. The player's item menu doesn't list kit items.
- [ ] `exit_combat` removes `used` from the vein kit on a win, loss or flee. Rewinding the fight doesn't restore spent units.
- [ ] Beats reuse the ally item beat types with `effectKey`. New log lines flagged PROSE-REVIEW. REFERENCE §3.7/§3.7a is updated.

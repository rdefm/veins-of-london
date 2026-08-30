# 05 — Combat Skill stat + Train action

**What to build:** Give the player a trainable Combat Skill stat, matching the progression shape `craftingSkill`/`cultivatingSkill` already have, that drives both attack power and turn-order speed — plus a new repeatable Train action at the HQ Home Gym to invest a time block into it directly, on top of what's earned just by fighting.

`player.combatSkill` (int, levels 1–5) and `player.combatXP` (int), leveled through the existing generic `Progression.award_xp()` mechanism, reusing the exact `[0, 0, 80, 220, 500, 1000]` XP curve `craftingSkill`/`cultivatingSkill` already use (no new curve authored). Two additive, level-indexed effects:

- **Attack bonus:** a level-indexed value added to both the player's `attackMin`/`attackMax` in `Combat.get_attack_range()`, before any equipped-weapon bonus. Level 1 must equal today's baseline (zero bonus) — additive-only, never regresses an existing save.
- **Speed:** a level-indexed value that becomes the player's entry in the turn queue's sort (built in ticket 02) — this replaces ticket 02's fixed placeholder player-speed constant. Allies and enemies remain non-trainable, using their own fixed authored `speed` values (unchanged from ticket 02).

**XP sources, two:** (1) a flat XP award once per player turn taken in combat (regardless of hit/miss/outcome — mirrors the Dial's flat-XP-per-cast shape, since "taking a turn" has no failure state to split on). (2) A new **Train** action, visible only once the Home Gym room is built, that consumes one of the player's three daily time blocks (same currency every other block-consuming HQ action already spends — Lab, veinStation, a James job fulfilment) and awards a larger flat XP amount, with no separate cooldown — the existing daily time-block scarcity is the only throttle. Home Gym's existing one-time `+10 hpMax` build bonus is unrelated and unchanged — Home Gym becomes dual-purpose (one-time stat bump on build, plus unlocking a repeatable action), not replaced.

**Blocked by:** 02 (replaces its player-speed placeholder)

**Status:** ready-for-agent

- [ ] `player.combatSkill` (default 1) and `player.combatXP` (default 0) exist in the player state shape
- [ ] `Combat.get_attack_range()` adds a level-indexed attack bonus (level 1 = 0, matching today's baseline exactly) to `attackMin`/`attackMax` before the weapon bonus
- [ ] The turn queue (ticket 02) sorts the player by a level-indexed Combat Skill speed value instead of the ticket-02 placeholder constant
- [ ] `Combat.player_attack()` awards a flat XP amount once per player turn taken, regardless of hit/miss/outcome
- [ ] A Train action exists, gated on the Home Gym room being built, consumes one time block via the existing `TimeSystem.advance_time_block()` mechanism, and awards a flat (larger) XP amount with no separate cooldown
- [ ] Leveling up uses `Progression.award_xp()` against the shared `[0, 0, 80, 220, 500, 1000]` curve — no new curve is authored
- [ ] Home Gym's existing one-time `+10 hpMax` build bonus is untouched and still applies independently of Train's unlock
- [ ] Regression test: at Combat Skill level 1, attack range and turn-order speed reproduce today's pre-this-spec numbers exactly
- [ ] New tests cover: XP award on a player turn taken, the Train action's cost/gate/award (blocked without Home Gym, spends a time block, awards XP when available), and the level-up curve correctly advancing `combatSkill` via the shared progression mechanism

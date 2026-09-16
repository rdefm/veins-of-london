# 02 — Speed-sorted turn queue

**What to build:** Replace round-synchronous resolution (player attacks, then every ally, then the one enemy, all inside one call) with a real per-combatant turn queue, so "who acts next" is an inspectable value built fresh each round rather than an implicit call order.

Each round, build one queue from every non-`koed` combatant (player, living allies, living enemies), sorted by `speed` descending. Ties break in a fixed order — player, then allies (array order), then enemies (array order) — no RNG in the sort. Each queue entry resolves as one atomic turn, reusing today's player-attack/ally-turn/enemy-turn resolution bodies, just invoked once per queue entry instead of once per round.

Frozen combatants (`frozenTurns`) keep their queue slot but their turn becomes a no-op-plus-decrement (same log line as today) rather than being removed from the queue. Motion (Enhancement Powder, or a loaded `enhancementPowder` Complication) changes from today's in-place 2×/3× attack loop inside one `player_attack()` call to one extra queue entry inserted immediately after the boosted combatant's own slot, for that round only — a visible second turn, not a hidden multiplier. Total damage output for a Motion-boosted round is unchanged; only its presentation in the queue changes.

This ticket needs a `speed` value for every combatant type to sort by: author a fixed `speed` value onto each enemy template in `data/enemies.json` (raid guards, home-raid raider) and onto the mugger archetype's generated stats; author a fixed `speed` value into each ally's combat kit constants (Contacts). The player's `speed` here is a **fixed placeholder constant** (not yet trainable) — Combat Skill's real level-indexed speed value replaces this placeholder in ticket 05. Flag the placeholder clearly in code so it's obviously provisional.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] A turn queue is built at the start of each combat round from every non-koed combatant (player, living allies, living enemy entries), sorted by `speed` descending, ties broken player > allies (array order) > enemies (array order), with no RNG in the sort
- [ ] Each queue entry resolves as one atomic turn, reusing the existing player-attack/ally-turn/enemy-turn resolution logic per combatant
- [ ] A frozen combatant's queue slot is a no-op-plus-decrement (same log line as today), not removed from the queue
- [ ] Motion (Enhancement Powder, consumable or Complication) inserts one extra queue entry immediately after the boosted combatant's own slot for that round only, rather than looping the attack in-place; total damage output for the round is unchanged from today's 2×/3× behavior
- [ ] Every enemy template in `data/enemies.json` and the mugger archetype carry an authored `speed` value; every ally combat kit carries an authored `speed` value
- [ ] The player's `speed` is a fixed, clearly-flagged placeholder constant pending ticket 05
- [ ] New tests assert queue *ordering* only (not re-testing per-turn resolution, which existing tests already cover): a given set of speeds produces the expected order, ties resolve player > allies > enemies, a frozen entry keeps its slot as a no-op, a Motion-boosted entry produces one extra queue entry immediately after its own slot

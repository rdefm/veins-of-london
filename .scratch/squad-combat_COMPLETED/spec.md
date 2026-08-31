# PRD — Squad combat, turn order, and Combat Skill

**Status:** ready-for-agent

**Written against** `collective1`, synthesised from the 2026-08-30 combat-UI
review session. Extracted out of `docs/REFERENCE.md` §3.7a, which remains the
canonical mechanics/formula reference — this PRD is the buildable slice of
that section, scoped for ticket breakdown. `docs/combat-animation-vision.md`
(§2.2/§2.3/§2.4) is the design pressure that produced this: its turn-order
strip and swipe-to-focus targeting have no state to render against without
this work landing first.

**Scope of authority:** canonical for what to build and in what shape. Any
numeric constant below (attack-bonus curve, speed curve, XP amounts,
`ENEMY_INSTANCE_VARIANCE`) is a placeholder shape, explicitly flagged
draft/needs-balance-sign-off in `REFERENCE.md` §3.7a — this PRD does not
attempt a balance pass, and no ticket built from it should block on one.

---

## Problem Statement

Combat today tracks exactly one enemy per fight (`combat.enemy`, a single
Dictionary) and resolves an entire round synchronously inside one
`player_attack()` call — player hits, then every ally, then the one enemy,
with no concept of individual turn order. This blocks two things at once:

1. **The combat-UI vision** (`docs/combat-animation-vision.md` §2.2–§2.4)
   calls for up to 3 independently-tracked enemies per fight, a swipe-to-focus
   targeting model, and a turn-order strip that reflows as initiative changes
   — none of which has any state to read today.
2. **Mob-count content already lies to the player.** `"3× Mugger"` and
   multi-guard raids are one scaled stat block wearing a plural name — there
   is no way to knock out one mugger while two remain standing, no per-enemy
   HP, and no way for an AoE effect (Black Hole) to mean anything beyond
   "hits the blob."

Separately, combat has no player-trainable stat at all — attack power and
(the yet-to-exist) turn speed are both fixed, with no progression lever
comparable to `craftingSkill`/`cultivatingSkill`.

## Solution

1. Replace the single-enemy combat state with a roster (**up to 3 distinct
   enemy entries**, each independently tracked), plus a **focused-target**
   index the player's single-target actions read from and the turn-order
   strip's swipe gesture writes to.
2. Replace round-synchronous resolution with a **speed-sorted turn queue**,
   interleaving both sides every round, so "who acts next" is a real,
   inspectable value rather than an implicit call order.
3. Introduce **Combat Skill**, a new trainable player stat (levels 1–5, same
   XP-curve shape as `craftingSkill`/`cultivatingSkill`) that drives both the
   player's attack bonus and their turn-order speed — trained by fighting and
   by a new repeatable **Train** action at the HQ Home Gym.
4. Convert mob-count content generation (muggers, raid guards) from "one
   stat block scaled by count" to **N distinct enemy instances**, each rolled
   off its archetype's base stats with independent variance, so squadmates
   read as individuals rather than a clone army.

## User Stories

1. As a player, I want each enemy in a multi-enemy fight to have its own HP bar, so that I can see the fight's actual state instead of one combined number.
2. As a player, I want to choose which enemy my attack hits, so that I can focus down a specific threat instead of always hitting an undifferentiated blob.
3. As a player, I want Black Hole (and future AoE effects) to hit every enemy on the field, so that an area effect is worth using against a squad rather than just the mob I happened to be focused on.
4. As a player, I want to see whose turn is coming up next across both sides of the fight, so that I can plan around a dangerous enemy's turn instead of being surprised by it.
5. As a player, I want a frozen enemy's turn to visibly skip in the turn order, so that Time Pearl/Black Hole's freeze effect reads as "they lose their turn" rather than an invisible internal counter.
6. As a player, I want Enhancement Powder to grant me a visible extra turn in the order, so that "moving fast" reads as "I act again soon" rather than a hidden multiplier on one attack.
7. As a player, I want each enemy in a squad to act and choose its own target independently, so that a 3-enemy fight doesn't still resolve as "one enemy's turn" mechanically.
8. As a player, if my focused enemy dies mid-round, I want my focus to move to another living enemy automatically, so that I'm never left targeting a corpse.
9. As a player, I want a fight to end only once every enemy on the field is down, so that "the fight" means the whole squad, not just whichever one I was focused on.
10. As a player, I want a 3-mugger fight to feel like fighting three different muggers (each with slightly different HP/attack), so that mob-count encounters aren't a reskinned single-target fight with a bigger number.
11. As a player, I want raid-guard squads to sometimes mix different guard types (e.g. a Scrapper alongside a Vein Guard), so that multi-guard raids have some variety instead of always being three of the same template.
12. As a player, I want a Combat Skill stat that levels up, so that fighting has the same kind of long-term progression crafting and cultivating already have.
13. As a player, I want my Combat Skill to make my attacks hit harder, so that training pays off in a way I can feel in numbers.
14. As a player, I want my Combat Skill to make me act earlier in a fight's turn order, so that training has a tactical payoff, not just a damage payoff.
15. As a player, I want to earn Combat Skill XP just by fighting, so that I don't have to do anything extra beyond playing the game normally to progress it.
16. As a player, I want a Train action at my Home Gym, so that I have an active, deliberate way to invest a time block into getting better at combat, on top of what fighting alone gives me.
17. As a player, I want the Train action to require the Home Gym room, so that investing in my HQ pays off with a new capability, not just a passive HP bump.
18. As a player, I want allies' turn-order speed to be fixed per-contact (not trainable), so that Combat Skill stays a player-specific investment rather than something I have to manage for every ally too.
19. As a developer maintaining enemy content, I want each enemy template to carry its own authored speed value, so that turn-order behavior is data-driven per archetype, not hardcoded per fight.
20. As a developer, I want the roster-generation change (distinct entries with variance) to be clearly flagged as a difficulty increase over today's blob-scaling, so that it isn't silently shipped into a live encounter without a balance/playtest pass.

## Implementation Decisions

- **State shape:** `combat.enemy: Dictionary` is replaced by `combat.enemies: Array` (0–3 entries). Each entry keeps today's single-enemy shape (`name, hp, hpMax, attackMin, attackMax, weapon, ability, evadeChance`) plus two new fields: `speed:int` and `koed:bool` (mirroring how `combat.allies` already tracks knocked-out members in place rather than removing them from the array). `combat.veinId` moves up to sit directly on the combat dict (one vein per fight regardless of guard count) rather than living on the old single enemy entry. A new `combat.focusedEnemyIndex:int` (default 0) tracks the player's current single-target.
- **Turn queue:** built fresh each combat round from every non-`koed` combatant (player, living allies, living enemy entries), sorted by `speed` descending. Ties break in a fixed order: player, then allies (array order), then enemies (array order) — no RNG in the sort. Each queue entry resolves as one atomic turn, reusing today's player-attack / ally-turn / enemy-turn resolution bodies, just invoked once per queue entry instead of once per round.
- **Frozen combatants** (`frozenTurns`) keep their queue slot but their turn is a no-op-plus-decrement, same log line as today — they are not removed from the queue.
- **Motion (Enhancement Powder / a loaded `enhancementPowder` Complication)** changes from an in-place 2×/3× attack loop inside one resolution call to **one extra queue entry inserted immediately after the boosted combatant's own slot**, for that round only. This is a visible extra turn, not a hidden multiplier — the effect on total damage output for that round is unchanged, only its presentation in the turn queue.
- **Targeting:** the player's single-target actions (Attack, Blast, and any Complication that isn't an AoE effect) always resolve against `combat.enemies[focusedEnemyIndex]`. Nothing else sets `focusedEnemyIndex` from the system layer — it's written by the UI's swipe gesture (out of scope here, see `docs/combat-animation-vision.md` §2.2/§2.4) and defaults to the first living enemy at combat start. If the focused enemy dies mid-round, `focusedEnemyIndex` auto-clamps to the next living enemy. The fight's win condition becomes "every entry in `combat.enemies` is `koed`," replacing today's single-enemy-hp-at-zero check.
- **AoE effects** (currently only Black Hole) ignore `focusedEnemyIndex` entirely and apply their full, un-diluted effect to every non-`koed` enemy independently — matching the no-per-target-dilution precedent the Dial's Spread Movement already established for multi-target casts.
- **Enemy AI targeting** keeps its existing shape (uniform-random over {player} ∪ {living allies}) unchanged — the only change is that it now runs once per enemy's own queue turn, independently per enemy, rather than once per round for the single enemy that used to exist.
- **Combat Skill (new player stat):** `player.combatSkill` (int, levels 1–5) and `player.combatXP` (int), leveled through the same generic XP-award mechanism `craftingSkill`/`cultivatingSkill` already use, reusing their exact `[0, 0, 80, 220, 500, 1000]` XP curve rather than authoring a new one.
  - **Attack bonus:** a level-indexed value added to both the player's `attackMin` and `attackMax` before any equipped-weapon bonus is applied. Level 1 must equal today's baseline (i.e. zero bonus), so this is additive-only and never regresses an existing save.
  - **Speed:** a level-indexed value that becomes the player's entry in the turn queue's sort. Allies and enemies are *not* trainable — each ally's combat kit and each enemy template carries its own fixed, authored `speed` value instead.
  - **XP sources, two:** (1) a flat XP award once per player turn taken in combat, regardless of hit/miss/outcome — mirrors the Dial's flat-XP-per-cast shape rather than crafting's hit/miss-split shape, since "taking a turn" has no failure state to split on. (2) A new **Train** action, available only once the Home Gym room is built, that consumes one of the player's three daily time blocks (the same currency every other block-consuming HQ action already spends) and awards a larger flat XP amount, with no separate cooldown — the existing daily time-block scarcity is the only throttle, deliberately not a new one.
  - Home Gym's existing one-time `+10 hpMax` build bonus is unrelated and unchanged by this — Home Gym becomes dual-purpose (a one-time stat bump on build, plus unlocking a repeatable action), not replaced.
- **Roster generation:** the mugger-count roll and the raid guard-count value both keep their existing ranges (muggers 1–3; guards capped at 3, the squad maximum), but each now spawns that many **distinct enemy entries** instead of one entry with stats scaled by the count.
  - Muggers: each of the `count` entries is independently rolled off the single existing "mugger" archetype's base stats (no new mugger archetypes are introduced by this spec).
  - Raid guards: each of the `guard_count` entries independently rolls which existing guard template to use (mixed-archetype squads become possible — e.g. one Scrapper alongside one Vein Guard) *unless* the caller has forced a specific template, in which case every entry uses that one.
  - **Per-instance variance:** every spawned entry (mugger or guard) has its HP and attack range independently rolled at a small percentage above/below its archetype's base values, so that two entries sharing the same archetype are not stat-for-stat identical.
  - This is called out explicitly as a **real difficulty increase** over today's single-blob scaling (three full-strength enemies vs. one enemy scaled to roughly three times the stats) and is not something this spec's tickets should treat as balance-neutral.
- **Not touched by this spec:** the ally roster's own shape and per-turn behavior beyond adding the new `speed` field; the win/loss/flee outcome dispatch table; the snapshot/Rewind mechanism beyond snapshotting the new `enemies` array and `focusedEnemyIndex` in place of the old single `enemy` field; every non-targeting consumable/Complication effect (Time Pearl, Shield, Healing Burst, Prophet's Breath, Wormhole) beyond however their existing "which enemy" logic changes shape from "the enemy" to "the focused enemy."

## Testing Decisions

- Same seam as every existing system test in this codebase: call the relevant static system functions directly against `GameState.state`, no mocking, no scene tree. This is the established pattern for every prior system test in this area (the existing combat tests, the Dial tests, the home/room tests) and this spec introduces no new seam.
- A good test here asserts on the resulting state shape and log/outcome, not on internal call order — e.g. "after N rounds, every enemy is koed and the outcome is win," not "player_attack was called exactly 3 times."
- Turn-queue tests should assert the queue's *ordering* (given a set of speeds, ties, a frozen entry, and a Motion-boosted entry) rather than re-testing the underlying per-turn resolution logic each existing test already covers.
- Roster-generation tests should assert the *shape* invariants (correct entry count, each entry's stats fall within its archetype's variance band, mixed-template raids are possible when not forced) rather than pinning exact rolled values — the existing seeded-RNG test helper pattern already used for mugger-count generation is directly reusable here.
- Combat Skill tests should cover: XP award on a player turn, the Train action's cost/gate/award, the level-up curve reusing the shared progression mechanism correctly, and that level 1 reproduces today's pre-this-spec numbers exactly (a regression guard, not a new-behavior test).

## Out of Scope

- **All combat-UI presentation** — the turn-order strip, swipe-to-focus gesture, stage/fan layout, nameplate cards, and the Dial widget redesign. That work is tracked in `docs/combat-animation-vision.md` and depends on this spec's state shape existing, but is not part of it.
- **Sprites, animation, the beat-queue/animation-director architecture** (`docs/combat-animation-vision.md` §8) — explicitly deferred by the human to a later pass.
- **Balance tuning** of any numeric constant introduced here (attack-bonus curve, speed curve, XP amounts, instance-variance percentage). All are placeholder shapes per `REFERENCE.md` §3.7a's own flag.
- **New enemy archetypes or content.** Roster generation draws only from templates that already exist in `data/enemies.json`; no new mugger or guard archetype is authored by this spec.
- **A display/flavour name for Combat Skill.** The mechanical field name is settled; what the player sees in the UI ("Physical Prowess" or otherwise) is a separate, later naming decision.
- **Threat-tier/encounter-scaling design** (`docs/VISION.md` §3b) — squad size and composition rules beyond "up to 3, drawn from the existing roster" are not addressed here.

## Further Notes

- This spec supersedes the "not designed" flags at `docs/combat-animation-vision.md` §2.3 items 1–2 and §13 items 5–6, and the corresponding milestone amendment note has already been added to `docs/VISION.md`'s M4 "Multi-enemy fights" paragraph — no further doc amendment is needed once this ships.
- `docs/REFERENCE.md` §3.7a is the canonical numeric/formula reference for everything in this spec; if the two ever disagree after this spec is broken into tickets, `REFERENCE.md` wins, per the project constitution.
- Ticket breakdown should probably separate along the four Solution points above (state-shape + turn-queue; targeting + roster generation; Combat Skill + Train action), since each is independently testable and the turn-queue work is the one most worth landing first — every other piece is easier to build once a real per-combatant turn exists to hang off of.

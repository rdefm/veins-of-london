# Enemy/ally level system — scoping note (not yet designed)

**Status:** flagged during ticket 02 (turn-order strip), deliberately **not
implemented**. This is a summary of what came up in conversation, not a
signed-off spec — it needs its own `REFERENCE.md` work and probably its own
ticket before any code lands, per the project constitution ("you execute
specs; you do not redesign mechanics... if a spec seems wrong, STOP and ask").

## How this came up

`docs/combat-animation-vision.md` §2.4's nameplate anatomy calls for a "small
level badge" on every turn-order-strip card. Checking the state model: only
the player has a level-like stat (`player.combatSkill`, 1–5, `docs/
REFERENCE.md` §3.7a). Enemy templates (`data/enemies.json`) and ally combat
kits (`Contacts.build_combat_ally()`) carry no `level` field at all.

## What was discussed

The user wants a real leveling axis, not a cosmetic stand-in:

- Enemies are **archetypes** (mugger, territorial scrapper, vein guard,
  orichalchum dealer, home-raid raider — the existing roster in
  `data/enemies.json` plus the procedural mugger) with their own **baseline
  stats**.
- Each archetype has its own **level curve** — how its stats grow per level.
- An encounter spawns a levelled instance of an archetype (e.g. "a level 2
  mugger"), then applies **a small amount of randomisation on top of that
  level's baseline stats** — i.e. level picks the baseline, then the existing
  per-instance variance (or something like it) rolls around that baseline,
  not around the archetype's level-1 stats.

Two proposals were floated and rejected as too thin:

1. A fixed per-archetype "danger rating" integer (Scrapper=1, Dealer=2,
   Guard=3, Raider=4, Mugger=1/2) — rejected: doesn't vary per spawn, isn't a
   real level.
2. Reusing the vein's `Cultivating.value_tier()` (1–6) as the guard's level —
   rejected as the *only* mechanism: conflates "how strong is the vein" with
   "what level is this specific guard archetype," and doesn't cover muggers
   or the home-raid raider at all (no vein).

Neither was confirmed as correct; both are recorded here as ruled-out
starting points, not as a fallback design.

## What's still unresolved

This needs real answers before implementation, not invention:

- **What determines a spawn's rolled level?** Fixed always-1? A random range?
  Does it scale with something existing (day count, district danger, the
  player's own `combatSkill`, `value_tier` of the vein in play)?
- **Does it replace or stack with existing scaling?** Raid guards already
  scale hp/attack off the target vein's `value_tier` in
  `Combat._spawn_guard_instance()`. Muggers already have a binary `harder`
  stat-scale (`Combat.generate_mugger(harder)`, vein-included muggings roll
  a wider/stronger roster). A new independent level axis on top of both is a
  third scaling knob on the same numbers — needs a decision on whether level
  *subsumes* one or both of these, or genuinely stacks with them.
- **Combat-math or display-only?** `docs/combat-animation-vision.md`'s own
  scope-of-authority line is explicit that it "does not define mechanics" —
  if level changes `hp`/`attackMin`/`attackMax`, that's a `REFERENCE.md` §3.7
  change, not a presentation one.
- **Curve shape per archetype.** What the actual per-level multipliers/deltas
  are — needs balance sign-off the same way `ENEMY_INSTANCE_VARIANCE`,
  `MUGGER_SPEED`, `COMBAT_ATTACK_BONUS_BY_LEVEL` etc. are all flagged
  "DRAFT, needs balance sign-off" in `systems/combat.gd` today.
- **Ally levelling.** Only Archie exists as a combat-eligible contact today
  (`docs/combat-animation-vision.md` §2.2's flagged content gap). Whether
  allies level at all, and via what (relation? a training loop?), wasn't
  discussed.

## Where this should land

Per the constitution's source-of-truth map, any resolved version of this
belongs in `docs/REFERENCE.md` (numbers/formulas/schema) with its own ticket
under `.scratch/combat-presentation/` or a new feature folder — mirroring how
`docs/combat-animation-vision.md` §2.3 flagged squad combat and turn-based
resolution as prerequisites needing dedicated `REFERENCE.md` work before
their UI could ship (resolved 2026-08-30 in §3.7a).

**Ticket 02 proceeds without this** — the turn-order strip's level badge
renders only on the player's card (`combatSkill`); enemy and ally cards
render the same nameplate layout with that corner empty until this system is
actually designed.

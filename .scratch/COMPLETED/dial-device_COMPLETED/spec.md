# PRD — The Dial device mechanic

**Status:** ready-for-agent

**Written against** `collective1`, synthesised from `docs/device-plan-spec.md`
(revision 2). That document remains the design log of record for flavour,
naming rationale, and the open items listed in its own §Open items — this PRD
extracts only the mechanics-and-data slice that's ready to build, per human
direction: **system layer only**. The Collar UI widget's scene/interaction/
haptics and the Collective Act 2 onboarding-quest integration are explicitly
out of scope here (see Out of Scope) and get their own specs later.

**Scope of authority:** canonical for the Dial's state shape and system
functions. Where it conflicts with `docs/device-plan-spec.md` on a mechanic
already marked "decided" in that doc, this PRD's restatement is informational,
not a new decision — `docs/device-plan-spec.md` is still the design log. Any
numeric constant below is a placeholder shape, not a final balanced value,
same status as every other undertuned formula in `docs/REFERENCE.md` until a
balance pass signs off — this PRD does not attempt that pass.

---

## Problem Statement

The player's single equippable device (`timeDevice`/`enhancementDevice`/
`rewindDevice`) is a dead end: one calc type, one fixed effect, a flat daily
charge allowance, and a progress-bar build that carries no further meaning
once complete. There's no room in it for player choice, no economy around
maintaining or upgrading it, and no connection to the game's established ore
and crafting systems beyond the device's own one-off build cost. It also
can't carry the story weight the Collective Act 2 material needs: nothing
about today's device says "rare," "crafted by you specifically," or
"something James already noticed."

## Solution

Replace the single-slot device outright with **the Dial** — one rare,
lifetime-owned instrument, seeded (not built on a progress bar) by a player
with a narrative "gift" for orichalchum. The Dial holds exactly one swappable
**Movement** (sets its attuned ore type, its charge economy, and its
amplification archetype) and loads any number of the player's existing
crafted consumable recipes as **Complications** up to a numeric capacity
budget. Casting a loaded Complication in combat spends **charge** from a
persistent pool (not a daily allowance) instead of destroying the item.
Charge is earned back by time passing (`rechargeRate`) or paid for directly
with calc (**winding**). The whole system reuses the crafting pipeline's
existing chance/tier/effect-power formulas rather than inventing new ones, so
a player's crafting and cultivating investment carries straight over.

## User Stories

1. As a player who hasn't reached the Act 2 story beat that grants the gift,
   I want the Dial-seeding action to be unavailable to me, so that the Dial
   stays narratively rare rather than appearing as just another crafting
   recipe.
2. As a player who has the gift, I want to attempt to seed a Dial by paying a
   mixed five-ore-type cost and rolling once, so that the attempt feels like
   the game's other big one-shot investments (vein seeding), not a
   progress-bar grind.
3. As a player whose seeding attempt fails, I want the full cost consumed
   with no partial progress retained, so that the risk is real and matches
   the vein-seeding model I already know.
4. As a player, I want my seeding success chance to be the average of my
   crafting skill's chance term and my cultivating skill's chance term, so
   that both of my skill investments matter for this one attempt.
5. As a player, I want it to be impossible to seed a second Dial once I have
   one, so that the Dial stays a singular, lifetime object rather than a
   stockpile.
6. As a player with a freshly-seeded Dial and no Movement seated, I want the
   Dial to be inert (no attunement, no charge, no regen), so that seating a
   first Movement is a meaningful, visible milestone.
7. As a player, I want to craft a Movement by choosing one ore type as its
   ingredient, so that the ore type I pick becomes the Dial's attunement for
   as long as that Movement stays seated.
8. As a player crafting a Movement, I want the normal recipe pipeline to
   apply (pay ingredients regardless of outcome, `craftChance` from my
   crafting skill, failure wastes the ingredients), so that Movement crafting
   doesn't need a parallel economy to learn.
9. As a player, I want to remove a seated Movement without destroying it, so
   that I can freely re-seat it later or try a different one without losing
   my crafting investment.
10. As a player, I want a Movement's tier to be set by the `qualityTier` it
    was crafted at, so that better crafting skill produces a better Movement
    through the same mechanism every other recipe already uses.
11. As a player using a low-tier Movement, I want a small bonus and
    essentially no downside, so that early Movements feel like a safe
    upgrade over having none.
12. As a player using a tier-5 Movement, I want a much bigger bonus paired
    with a real, moderate trade-off, so that no Movement ever becomes a pure
    upgrade regardless of how much I've levelled my crafting skill.
13. As a player, I want each of the four Movement archetypes (Recharge,
    Capacitor, Impact, Spread) to bias charge economy or effect magnitude in
    a distinct, named direction, so that choosing a Movement is a strategic
    identity choice, not a numeric-only decision.
14. As a player using a tier-5 Recharge Movement, I want my charge pool to
    passively regenerate during combat itself, so that this archetype's
    top-tier payoff is qualitatively different from just "more of the same
    stat," matching its self-sustaining-if-paced identity.
15. As a player using a tier-5 Capacitor Movement, I want my natural
    `rechargeRate` to drop to zero, so that the archetype's enormous reserve
    comes with a real commitment to active winding rather than being a free
    upgrade.
16. As a player using a Spread Movement, I want an extended-target cast to
    hit every target at full power with no per-target dilution, so that
    Spread is never strictly worse than Impact at the same charge cost.
17. As a player, I want my Movement's attuned ore type to grant a flat bonus
    to the relevant success-chance formula (cultivating, crafting, seeding,
    and future discovery/refine chances) whenever that action's ore type
    matches the attunement, so that my Movement choice pays off outside
    combat too, not just in casting.
18. As a player, I want that attunement bonus to depend only on which
    Movement is currently seated — never on what's currently loaded into my
    Complications — so that I can't game the bonus by swapping loadouts
    right before an action.
19. As a player, I want to load any of my existing crafted consumable
    recipes directly into the Dial as Complications, so that I don't need to
    learn or stock a separate "artefact" item category.
20. As a player loading a Complication, I want the unit moved out of my
    regular tiered inventory (not duplicated or destroyed), so that loading
    and unloading are fully reversible.
21. As a player, I want each recipe's Complication capacity cost to be fixed
    regardless of the crafted quality tier of the unit I load, so that
    crafting a better version of something I already use is never a
    footprint downside.
22. As a player, I want casting a loaded Complication in combat to spend one
    charge rather than consuming the item, so that a well-stocked Dial lets
    me act repeatedly without restocking mid-fight.
23. As a player, I want throwing a consumable directly (not loaded into the
    Dial) to still destroy the unit on use exactly as today, so that the
    existing direct-use path (including selling to Archie) is unaffected.
24. As a player, I want my total loaded Complication capacity cost to never
    exceed my Dial's capacity budget, so that the Dial enforces a real
    loadout choice rather than letting me load everything I own.
25. As a player, I want my Dial's capacity budget to grow only with Dial
    level, never with which Movement is seated, so that my loadout ceiling
    is a stable long-term investment independent of my current tactical
    Movement choice.
26. As a player, I want a cast's base effect to come from the loaded unit's
    crafted `effectPower` at its tier, amplified further by my Dial/Movement
    archetype, so that crafting investment and Movement investment stack
    rather than compete.
27. As a player, I want my charge pool to be a persistent `currentCharge`/
    `maxCharge` value that carries across days, so that charge management
    feels like a resource I husband over time, not a daily allowance that
    resets regardless of how I used it.
28. As a player, I want natural charge regeneration (`rechargeRate`) to tick
    once per day as part of the existing daily cycle, so that charge
    replenishment fits the rhythm I already know from vein growth and other
    daily systems.
29. As a player, I want to spend calc of my Movement's attuned ore type to
    manually add charge ("winding") at any time, with no time-block cost, so
    that I'm never forced to choose between winding and my three daily
    action blocks.
30. As a player, I want winding's calc-cost-per-charge to depend only on my
    Movement's archetype and tier — never on my Dial's level or `maxCharge`
    size — so that levelling up the Dial never makes winding more expensive.
31. As a player, I want gaining Dial XP (from casting) to grow both
    `maxCharge` and capacity as the primary per-level curves, with
    `rechargeRate` growing on a slower, occasional curve, so that levelling
    reads as "bigger reserve now, refills faster as a rarer milestone."
32. As a player with an existing save from before the Dial shipped, I want my
    old device progress/completion state and the `craftingUnlocked`/
    `enhancementUnlocked` flags to carry forward sensibly (as a cleared/null
    Dial slot, with the old recipe unlocks preserved as loadable
    Complication recipes), so that my save doesn't break or silently lose
    earned unlocks.
33. As a player, I want attempting any Dial action (seed, craft/seat/unseat a
    Movement, load/unload/cast a Complication, wind) against an invalid
    state (no gift, no Dial, no Movement seated, insufficient charge,
    insufficient calc, over capacity) to fail cleanly with a reason, so that
    the UI layer built on top of this system never has to guess why an
    action didn't go through.

## Implementation Decisions

- **New module, one seam:** `systems/dial.gd` (static funcs only, same
  discipline as every existing system) becomes the single place Dial logic
  lives. `systems/devices.gd` and `data/devices.json` are deleted outright —
  not kept alongside — per the design doc's "old devices retired outright"
  decision. `systems/combat.gd`'s device-casting call site and
  `systems/time_system.gd`'s daily_tick device-reset step are updated to call
  into `dial.gd` instead, mirroring exactly how they call into `devices.gd`
  today (same integration shape, new target).
- **State shape:** `player.equipment.device`, `player.devicesInProgress`, and
  `player.devicesCompleted` are replaced by a single `player.dial: {...} |
  null`. While seeded, it carries: current level/XP, `currentCharge`/
  `maxCharge`, capacity budget, the seated Movement (or null — a Dial can
  exist with no Movement), and a `loadedComplications` list (recipe key,
  tier, capacity cost, detent position). A cosmetic `haftId` field records
  the player's chosen haft for display only — no stat lookup ever reads it.
  Exact field names are an implementation detail for whoever picks up the
  ticket, not a design decision; the shape above is the agreed contract.
- **Gift gate:** a boolean player flag (alongside the existing flags like
  `craftingUnlocked`) gates the seeding action. This PRD does not set that
  flag — that's the Act 2 quest's job (Out of Scope) — it only reads it.
- **Seeding formula:** success chance = average of a `craftChance`-style term
  (crafting skill) and a `cultChance`-style term (cultivating skill), reusing
  both existing formulas rather than adding a third. Cost is a mix across all
  five ore types, life-weighted, consumed in full on the attempt regardless
  of outcome — single-roll risk model, same shape as `Sites.attempt_seed`
  (pay cost, roll once, fail = cost gone, no partial progress).
- **Movement crafting:** goes through the existing recipe-crafting pipeline
  (`Crafting.attempt_craft`-equivalent call), with the player's chosen ore
  type recorded on the resulting Movement instance as its attunement.
  Movement tier = `Crafting.quality_tier()`'s existing result at craft time.
  Each Movement archetype's bonus/downside curves are tier-indexed arrays
  (mirrors `effectPower[skill]`'s existing array-of-arrays shape: one bonus
  array, one downside array, keyed by tier) rather than a formula, so
  designers can hand-tune the ramp the same way `effectPower` is hand-tuned
  today.
- **Attunement bonus:** a flat additive bonus to whichever chance formula the
  current action uses (`cultChance`, `craftChance`, the Dial's own
  `seedSuccessChance`-style term, and future discovery/refine chances once
  those ship), applied only when the action's ore type matches the seated
  Movement's attunement. Magnitude scales with Movement tier. Driven
  exclusively by the seated Movement — never by loaded Complications — so
  there is no pre-action swap-in/swap-out to game.
- **Complications:** loading moves one unit from `Crafting`'s existing
  tier-bucketed inventory into the Dial's `loadedComplications`, unchanged in
  tier; unloading reverses it. Each recipe gets a new fixed capacity-cost
  field in its data definition (independent of crafted tier). Casting a
  loaded Complication spends one charge and computes its effect from
  `Crafting.effect_power()` at the loaded unit's tier, then applies the
  seated Movement archetype's amplification on top. Throwing a consumable
  directly (today's path) is untouched — still destroys the unit, no
  amplification, same call site as today.
- **Charge model:** persistent `currentCharge`/`maxCharge` on the Dial
  instance. Natural regen (`rechargeRate`, possibly fractional) ticks once in
  `time_system.gd`'s daily_tick, replacing `Devices.reset_daily_charges()`'s
  step. Winding is an instant, calc-only action with no time-block cost;
  its cost-per-charge is a lookup keyed by (archetype, tier) only — never by
  the Dial's own level or `maxCharge` — so progression never makes winding
  worse. Winding's calc type is always the seated Movement's attunement.
- **Leveling:** Dial XP grows from casting (mirrors the old device-activation
  XP award). `maxCharge` and capacity are the primary per-level curves
  (existing `DEVICE_XP_LEVELS`-style table mechanism, reused); `rechargeRate`
  grows on a sparser curve. Movements never modify capacity — capacity is
  Dial-level-only, kept structurally separate from any future
  second-Movement-slot milestone (explicitly not in scope for v1).
- **Hafts:** pure cosmetic data (id, faction-flavoured display name/art hook)
  with no stat fields and no code path that reads a haft for anything but
  display. Swapping a haft is a trivial field write on `player.dial.haftId`
  with no validation beyond "haft exists" — there is no minimum-barrel-length
  *check* to implement, since the design doc treats the barrel gate as
  satisfied by every haft in the whitelist by construction (no haft short
  enough to fail it is ever offered as a choice).
- **Ownership enforcement:** once `player.dial` is non-null, the seeding
  action is refused outright (story/UI layer never needs to hide the option
  itself — the system call is the single source of truth for whether seeding
  is currently legal).

## Testing Decisions

- **Seam:** every test calls `Dial.*` static functions directly against
  `GameState.state` and asserts on the resulting state/return dict — no scene
  instancing, no input simulation. This is the same pattern `tests/
  test_devices.gd`, `tests/test_sites.gd`, and `tests/test_crafting.gd`
  already use, and it's the only seam this PRD introduces.
- **Determinism for chance rolls:** use `Rng.set_seed(seed)` before each
  probabilistic call (seeding, Movement crafting) exactly as `tests/
  test_devices.gd`'s `device_build_progress_ladder_10_to_100_in_18_successes`
  case does — loop over seeds until the desired outcome (success/failure) is
  observed, rather than asserting on a specific seed's result.
- **What to test, grouped by decision above:**
  - Gift gate refuses seeding with no flag set; succeeds once set.
  - Seeding consumes the full multi-ore cost on both success and failure;
    failure leaves no partial Dial state; success leaves an inert,
    no-Movement Dial.
  - Seeding is refused outright once `player.dial` is non-null (no second
    Dial, ever).
  - Movement crafting follows the existing recipe cost/chance contract
    (ingredients always spent; `craftChance` gates success) and records the
    chosen ore type as attunement on success.
  - Seating/unseating a Movement is fully reversible — unseating returns it
    to inventory intact, not destroyed.
  - Attunement bonus applies to a matching-ore-type action and does not
    apply to a mismatched one; changes immediately when a different
    Movement is seated.
  - Loading a Complication decrements regular inventory and appends to
    `loadedComplications` at the recipe's fixed capacity cost, independent of
    crafted tier; unloading reverses it exactly.
  - Loading is refused once it would push `capacityUsed` past
    `capacityMax`.
  - Casting a loaded Complication spends exactly one charge and does not
    touch inventory; casting with `currentCharge` at 0 is refused.
  - Casting a directly-used (unloaded) consumable still destroys the unit
    and applies no amplification — a regression check against the existing
    direct-use path.
  - Winding adds charge, spends the Movement's attuned ore type, and its
    cost-per-charge is unaffected by Dial level/`maxCharge` at a fixed
    archetype/tier.
  - Daily regen adds `rechargeRate` to `currentCharge` exactly once per day,
    capped at `maxCharge` — mirrors the existing `lastResetDay`-guarded
    pattern in `Devices.reset_daily_charges()`.
  - Dial XP award grows `maxCharge`/capacity on the level curve and
    `rechargeRate` on its sparser curve — a level-ladder test in the same
    shape as the existing device XP ladder test.
  - Old-save migration: a save with populated `devicesInProgress`/
    `devicesCompleted`/`equipment.device` and no `player.dial` loads without
    error into a null-Dial state, and `craftingUnlocked`/`enhancementUnlocked`
    stay true.

## Out of Scope

- **The Collar UI widget** — its scene, drag-to-detent interaction, haptic
  feedback, and the wrap-around-vs-hard-stops decision. The design doc
  itself flags a haptic-fidelity on-device spike as a prerequisite to
  designing the widget further; that spike and the widget spec both come
  later.
- **Collective Act 2 onboarding integration** — the James-relation threshold
  that unlocks asking about the gift, and the quest beats that set the gift
  flag and walk the player through their first seeding. This PRD only reads
  the flag the quest will set; the quest's own spec owns the threshold number
  and beat sequence.
- **The supply-problem fiction** (whether a Dial binds to a person present at
  its seeding) — flagged in the design doc as needing human sign-off before
  it reaches `docs/REFERENCE.md`. It only affects faction/quest prose about
  *why* Dials are scarce, not any mechanic in this PRD — `player.dial`
  singularity is already enforced regardless of which fictional
  justification wins.
- **A second Movement slot** — acknowledged late-game stretch goal in the
  design doc, explicitly not v1.
- **Seeding Dials for other people** — deliberately out of scope for 1.0 per
  the design doc; flagged there as a post-1.0 hook.
- **Exact numeric balance** — archetype bonus/downside numbers per tier,
  winding cost-per-charge per archetype/tier, Spread's extra-target count by
  tier, seeding's exact multi-ore cost, and Movement recipe ingredient costs
  are all placeholder shapes pending a balance pass, same as every other
  undertuned formula already in `docs/REFERENCE.md`.
- **Promotion to `docs/REFERENCE.md`** — this PRD and its source design doc
  stay the spec of record until a human signs off and a milestone doc slots
  these tickets into the task order, per the design doc's own status line.

## Further Notes

- All draft flavour lines quoted from `docs/device-plan-spec.md` (the James
  jar, the Collar's audible-click beat, the faction-haft table's "the tell"
  column) are `PROSE-REVIEW:` material already flagged in that source
  document — none of it is this PRD's to re-flag, and none of it is approved
  player-facing copy.
- The design doc's Movement archetype → real-watch-movement mapping
  (Recharge/automatic, Capacitor/manual-wind, Impact/striking, Spread/
  regulator) is art/naming direction only, not a mechanical decision — it
  doesn't appear in Implementation Decisions above for that reason, but
  whoever writes Movement display names and art should pull it from the
  source doc's §Horology mapping.
- `docs/REFERENCE.md` §1.4 and §2's `devicesInProgress`/`devicesCompleted`/
  `equipment.device` rows, and §3.5's "Devices:" and "Device activation in
  combat" bullets, all need amending once this lands — the design doc's own
  scope note already calls this out, restated here so the ticket that lands
  the first Dial code is the one that amends them (project constitution
  rule: the winning document amends the one it supersedes in the same
  ticket).

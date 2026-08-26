# Device mechanic — design decisions (draft)

Status: brainstorm via `/grill-me`, complete. Not yet promoted to REFERENCE.md — treat as a design log, not spec, until human sign-off and a milestone doc slots the implementation tasks into the task order. Numeric constants throughout are placeholders/shapes, not final values — same "needs balance sign-off" status as any other undertuned formula in REFERENCE.md.

## Naming
- **Dial** — the device itself. Worn on/near the body (fob, timepiece-adjacent object). Chosen over "tally" (too England/Exchequer-specific for a millennia-old, non-London-bound phenomenon) and "obol"/"stater" (ancient-coin names risk reading as a second currency alongside cash/ore).
- **Movement** — the swappable core (real horology term: a watch's internal mechanism). A Dial with no Movement slotted is inert — can't hold or regenerate charge, no attunement. Chosen over generic "core" to stay in the register of real repurposed vocabulary (orichalchum, terroir, growth).
- **Complications** — the loaded-effect slots (real horology term: additional watch functions beyond timekeeping, each occupying mechanical space). Capacity budget = "complication capacity"; one loaded unit = "a complication."

## Scope
Replaces/absorbs the existing devices.json system (`timeDevice`/`enhancementDevice`/`rewindDevice`, one calc type + one effect each, `player.equipment.device` single slot, `devicesInProgress`/`devicesCompleted` progress-bar build). Old devices retired outright, not kept alongside. Their unlock flags (`craftingUnlocked`, `enhancementUnlocked`) and recipe links (timePearl/enhancementPowder/rewind) carry forward as the first loadable recipes.

## Ownership
- Exactly one device per player, ever. No second device craftable once one is seeded successfully.
- One core slot for the device's lifetime, v1. A second core slot is an acknowledged late-game stretch goal (not in scope now) — earned, not default.

## Creation (the device itself)
- Seeding cost: a mix of calc across all 5 ore types, life-weighted (flavour: a "living" device attuned to you) — generic/fungible cost, no lasting ore-type identity on the device itself.
- Single-roll risk model (vein-seeding style, not the old progress-bar model): pay the full cost, roll once. Fail = cost is gone, no partial progress carried over, try again whenever affordable.
- Success chance = **average of** a `craftChance`-style term (crafting skill) **and** a `cultChance`-style term (cultivating skill) — reuses both existing formulas rather than inventing a third.
- A freshly-seeded device is inert with no core slotted: no attunement, no recharge, can't hold charge. Slotting a first core is the "now it works" milestone.

## Cores
- Crafted like a normal recipe: player picks **one** ore type as the core's ingredient; that ore type becomes the device's attunement for as long as that core stays slotted. Standard recipe mechanics (pay ingredients always, `craftChance` from crafting skill, fail wastes ingredients).
- Cores are **not destroyed** when unslotted — removed to inventory, freely re-slottable. Swapping is reversible; the cost gate is the core's crafting investment, not a destruction penalty.
- Core **tier** = the crafted `qualityTier` (existing skill-tier mechanism, §3.5 REFERENCE.md) — not a separate unlock ladder. Each core archetype recipe carries a paired bonus-curve and downside-curve indexed by crafting skill (mirrors `effectPower[skill]`, just two arrays instead of one):
  - Tier 1–2 (low skill): small bonus, ~no downside.
  - Tier 3–4: bigger bonus, small downside.
  - Tier 5: much bigger bonus, real (moderate) trade-off.
  - No core is ever a pure upgrade at any tier — trade-offs stay meaningful at max skill.
- Core axes (v1): charge economy (`maxCharge`, `rechargeRate`, manual-recharge calc cost/efficiency) and effect amplification. Cores never touch artefact capacity (see below) or the 2nd-core-slot milestone.
- **Passive ore-type efficiency bonus** (from your original brainstorm) is driven **only** by the core's attuned ore type — never by what's currently loaded in slots. (Loadout-driven would be trivially gameable via pre-action swap-in/swap-out; core-driven keeps it a strategic, rare choice.) Flat additive bonus to the relevant success-chance formula (`cultChance`, `craftChance`, `seedSuccessChance`, and future discovery/refine chance once M3 ships) when the action's ore type matches the core's attunement; magnitude scales with core tier.

## Charge model
- Persistent `currentCharge`/`maxCharge` pool — **not** a full daily reset (departs from the old `chargesPerDay`/`chargesUsedToday` model).
- Natural regen: `rechargeRate` (charges/day, possibly fractional) ticks on the daily cycle.
- Manual recharge: spend calc outside combat to add charge faster. Calc type is always the core's attuned ore type (locked to whichever core is currently slotted — re-slotting a different core changes the recharge fuel type going forward). Exact cost formula: TBD.
- Device leveling (XP, existing `DEVICE_XP_LEVELS`-style table) grows **both** `maxCharge` and artefact capacity as the primary curves, with `rechargeRate` growing on a slower/occasional curve (bigger stat grows every level; rarer stat grows every few levels) — reads as "bigger reserve now, refills faster as a rarer milestone."

## Artefact slots (loadout)
- No separate "artefact" item category / no duplicate crafting list. **Existing consumable recipes are loaded directly into the device.**
- Loading is non-destructive: moves one unit from the tiered inventory bucket (`Crafting.inventory` shape, §2) into `device.loadedItems`, preserving its crafted tier/quality. Unloading reverses this — back to inventory, unconsumed.
- Casting a loaded item spends a **device charge**, not the item. The same recipe used the old way (thrown directly in combat, sold to Archie) still destroys a unit on use, exactly as today — destruction-on-use stays exclusive to that path.
- Slot capacity is a **numeric budget** (`capacityUsed <= capacityMax`), not discrete typed/shaped sockets. Each recipe has a **fixed** capacity cost (e.g. Blast=3, Time Pearl=1, Shield=2) regardless of crafted quality tier — quality only scales `effectPower`, never footprint (so better crafting is never a downside).
- Capacity grows with device **level only** — cores never modify it (kept separate from the 2nd-core-slot milestone, which also isn't a capacity mechanic).

## Casting / combat
- Base effect = `effectPower` at the loaded unit's crafted quality tier (existing formula, unchanged).
- Device/core amplification layers on top of the base effect (damage amplification, frozen-turns duration, effect breadth/number of targets, etc., per core archetype). Exact amplification formulas: TBD.
- Directly-used consumables (not loaded into the device) get no device amplification — same as today.

## UI / navigation
- HQ is being restructured into three sub-sections: **Lab** (crafting/recipes/experimenting), **Facilities** (rooms/security/property tier — old `property`), **Practice** (skill training [not yet built] + houses the Dial). "Practice" chosen over "Discipline"/"Conditioning" (too martial/gym-only) or "Development" (reads corporate-HR, risks a wink) — a real trade word covering both ongoing training and instrument upkeep.
- **Creation** (seeding the Dial, crafting a Movement) lives in HQ → Practice — a workbench-style, deliberate action, matching how big one-time crafting investments already work.
- **Day-to-day management** (swapping Movements, loading/unloading Complications) is available from **both** the global BagDrawer (matches existing weapon-equip / old device build-attempt-abandon pattern, reachable mid-run from anywhere) **and** HQ → Practice (so a new player can load Complications immediately after crafting, without leaving HQ). Both surfaces call the same underlying system functions — no duplicated logic.
- **Onboarding is narrative, not a standalone tutorial event**: Dial-seeding is built into **The Collective Act 2** questline, not a generic post-tutorial unlock. Archie points the player to James for an edge against The Firm; reaching a James-relation threshold (exact number owned by the Act 2 quest spec, not this doc) unlocks asking him about it; James teaches Dials and helps craft the player's first one. No separate `dialUnlocked`-style onboarding event needed outside that quest.

## Movement archetypes (v1 launch set: four)
Each has its own tier-scaled bonus/downside curve (per §Cores above); the *defining* trait below is specifically a **top-tier (tier 5)** payoff, not present at lower tiers — lower tiers just lean numerically toward the same axis without the qualitative shift.

- **Recharge** — biases `rechargeRate` up, `maxCharge` down. **Top-tier defining trait: in-combat regen** — the charge pool passively ticks up during a fight itself (e.g. +1 charge every N player turns), the only archetype whose top tier changes *when* charge regenerates (every other Movement only recharges between fights/via manual calc spend). Identity: very few charges, but effectively self-sustaining if paced.
- **Capacitor** — biases `maxCharge` way up. **Top-tier defining trait: zero natural `rechargeRate`** — charge only ever comes from manually spending calc, never from time passing. Identity: huge reserve, but must be actively fed or it stays empty.
- **Impact** — biases raw effect magnitude (damage/heal amount/freeze duration) up, steepest `maxCharge` penalty of the amplify pair. Purely numeric, no qualitative top-tier hook — the archetype's whole appeal *is* the raw number. Identity: a small number of devastating single-target casts.
- **Spread** — extends a normally single-target effect to hit/heal multiple targets, **at full power per target, no dilution** (splitting power across targets would make it strictly worse than Impact for the same charge cost, defeating the point). Cost lives entirely in charge economy, not in diluted output. Exact extra-target count by tier: TBD, balance pass later. Identity: fewer casts, but each one covers the whole fight.

No archetype is ever a pure upgrade at any tier (per the core tier-ramp rule) — all four keep a real trade-off even at tier 5.

## Manual recharge
- **Instant, no time-block cost** — unlike Seed/Cultivate/Prune (each 1 block), recharging the Dial is a free background action, calc-cost only. Keeps it from competing with the game's other core loops for the scarce 3-blocks/day resource.
- Calc cost is always the currently-slotted Movement's attuned ore type.
- Cost-per-charge depends **only on Movement archetype + tier**, never on the Dial's own level/`maxCharge` size — Capacitor's tier ladder naturally includes the cheapest manual-recharge rate (its whole reason to exist); other archetypes pay a pricier "backup" rate. Independent of level so progression never makes the mechanic worse.
- No artificial daily cap beyond ore affordability (ore scarcity is the real constraint, same as every other calc-gated action in the game).

## Open items (numbers only — shape is decided)
- Exact bonus/downside numbers per archetype per tier (needs balance sign-off, same status as every other undertuned formula in REFERENCE.md).
- Exact manual-recharge calc-cost-per-charge numbers per archetype/tier.
- Exact Spread extra-target count by tier.
- Exact seeding base-cost numbers (the multi-ore-type, life-weighted mix) and Movement recipe ingredient costs.
- State schema: how `player.equipment.device` and `devicesInProgress`/`devicesCompleted` get replaced — almost certainly a single `player.device: {...} | null` object (Dial), plus its slotted Movement and `loadedComplications` list, but not yet drafted field-by-field. Deferred to implementation-planning time, not a design question.

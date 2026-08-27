# Device mechanic — design decisions (draft)

Status: brainstorm, revised. Not yet promoted to REFERENCE.md — treat as a design log, not spec, until human sign-off and a milestone doc slots the implementation tasks into the task order. Numeric constants throughout are placeholders/shapes, not final values — same "needs balance sign-off" status as any other undertuned formula in REFERENCE.md.

Revision 2 folds in the physical-object pass: what a Dial actually *is*, why it is rare, what it is fitted to, and how the player turns it. The mechanical skeleton from revision 1 (charge pool, capacity budget, Movement archetypes, trade-off ramp) is unchanged except where noted.

Contains draft flavour lines, marked inline. **PROSE-REVIEW** — none of it is final player-facing text.

## Naming

The device is a small, rare, calibrated instrument that is fitted to a large, common, disposable one. Six terms:

- **Dial** — the device itself, and the only rare part. A round calibrated collar, machined, that seats around the top of a haft's handle and turns under the thumb. Everything valuable, gift-made, and registered is the Dial. Chosen over "tally" (too England/Exchequer-specific for a millennia-old, non-London-bound phenomenon) and "obol"/"stater" (ancient-coin names risk reading as a second currency alongside cash/ore).
- **Movement** — the swappable core inside the Dial (real horology term: a watch's internal mechanism). A Dial with no Movement seated is inert — can't hold or regenerate charge, no attunement. Chosen over generic "core" to stay in the register of real repurposed vocabulary (orichalchum, terroir, growth).
- **Complications** — the loaded-effect slots (real horology term: additional watch functions beyond timekeeping, each occupying mechanical space). Capacity budget = "complication capacity"; one loaded unit = "a complication." Physically, one complication sits at one detent on the Dial.
- **Haft** — the mundane object the Dial is fitted to. Umbrella, walking stick, telescopic baton, snooker cue. Provides the barrel (below). Cosmetic and replaceable; carries no stats and no narrative weight.
- **Barrel** — the straight rigid channel running the length of the haft, down which a discharge travels before release. A minimum length gate, not a stat — see §Hafts.
- **Ferrule** — the far end of the barrel. The muzzle. Real umbrella/cane term.
- **Catch** — the release. Turn the Dial to select a complication, press the catch to fire. Sits where an umbrella's spring catch already sits.

Naming collision to avoid: **barrel** is also the horological term for the drum that houses a mainspring. In this project "barrel" always means the haft's channel. If the Movement's reserve ever needs a name, it is **the spring**, never the barrel.

## Scope

Replaces/absorbs the existing devices.json system (`timeDevice`/`enhancementDevice`/`rewindDevice`, one calc type + one effect each, `player.equipment.device` single slot, `devicesInProgress`/`devicesCompleted` progress-bar build). Old devices retired outright, not kept alongside. Their unlock flags (`craftingUnlocked`, `enhancementUnlocked`) and recipe links (timePearl/enhancementPowder/rewind) carry forward as the first loadable recipes.

## The gift — why Dials are rare

Three independent scarcity gates, in ascending order of importance:

1. **Cost.** Seeding a Dial is expensive in calc across all five ore types (see §Creation).
2. **Control.** Organisations regulate creation. You cannot control an object that anyone can make, but you can absolutely control the handful of people who can make one — which is what the factions do, and what the Conclave keeps records of.
3. **The gift.** A Dial can only be seeded by a crafter with a natural affinity for orichalchum. Skill is not enough and never becomes enough. Most crafters — including good ones — will never make a Dial no matter how far they level, because the capacity is not learnable.

Gate 3 is the load-bearing one. It is what makes Dials rare rather than merely expensive, and it is what makes the people who can make them valuable enough to be worth controlling.

### How this pays off the existing setup

Already planted, unaltered, in `data/events/james_meeting.json`:

- A sealed jar on James's shelf "contains something that shifts — not from the movement of the shelf, not from any air in the room. It moves, very slightly, as if it noticed you."
- "You glance up. James is watching you. His expression doesn't change, exactly. But something in it does."
- Closing beat: "the distinct impression that James noticed something — and has decided, for now, not to mention it."

That is the gift, and James clocked it in the tutorial. The Collective Act 2 Dial questline is the moment he finally mentions it. No new foreshadowing needs writing; the payoff was set up before the mechanic existed.

### Mechanical shape

- The gift is a **prerequisite flag**, not a curve. It gates access to the seeding action; it does not modify any roll.
- The existing seeding roll (§Creation) is unchanged — crafting and cultivating skill still determine whether the attempt succeeds. The gift decides whether you may attempt it at all.
- The player has the gift. This is a fact about the player character, established narratively, not a stat they raise.

### Open question — the supply problem (needs sign-off)

If the player can make Dials, why can they only ever have one, and why don't they manufacture and sell them?

Proposed answer, **not yet decided**: a Dial is seeded *to a person*, who must be present at the seeding, and binds to them. A gifted maker therefore supplies the trade one bespoke Dial at a time, at enormous cost, which is exactly why gifted makers are controlled rather than rich. The player could in principle seed Dials for other people — deliberately out of scope for 1.0, and a strong late-game/post-1.0 hook, and a reason every faction wants the player specifically.

This preserves "exactly one device per player, ever" (§Ownership) with fiction rather than fiat. Flagged as a design decision the human should confirm before it goes near REFERENCE.md.

## Ownership

- Exactly one Dial per player, ever. No second Dial craftable once one is seeded successfully. (See the supply-problem question above for the fiction that justifies this.)
- One Movement slot for the Dial's lifetime, v1. A second Movement slot is an acknowledged late-game stretch goal (not in scope now) — earned, not default.
- Hafts are not owned in the singular. A Dial comes off one haft and goes onto another freely (§Hafts).

## Creation (the Dial itself)

- **Gated on the gift** (§The gift). Not offered to a player who hasn't reached that story beat.
- Seeding cost: a mix of calc across all 5 ore types, life-weighted (flavour: a "living" device attuned to you) — generic/fungible cost, no lasting ore-type identity on the Dial itself.
- Single-roll risk model (vein-seeding style, not the old progress-bar model): pay the full cost, roll once. Fail = cost is gone, no partial progress carried over, try again whenever affordable.
- Success chance = **average of** a `craftChance`-style term (crafting skill) **and** a `cultChance`-style term (cultivating skill) — reuses both existing formulas rather than inventing a third.
- A freshly-seeded Dial is inert with no Movement seated: no attunement, no recharge, can't hold charge. Seating a first Movement is the "now it works" milestone.

## Movements

- Crafted like a normal recipe: player picks **one** ore type as the Movement's ingredient; that ore type becomes the Dial's attunement for as long as that Movement stays seated. Standard recipe mechanics (pay ingredients always, `craftChance` from crafting skill, fail wastes ingredients).
- Movements are **not destroyed** when removed — they go back to inventory, freely re-seatable. Swapping is reversible; the cost gate is the Movement's crafting investment, not a destruction penalty.
- Movement **tier** = the crafted `qualityTier` (existing skill-tier mechanism, §3.5 REFERENCE.md) — not a separate unlock ladder. Each Movement archetype recipe carries a paired bonus-curve and downside-curve indexed by crafting skill (mirrors `effectPower[skill]`, just two arrays instead of one):
  - Tier 1–2 (low skill): small bonus, ~no downside.
  - Tier 3–4: bigger bonus, small downside.
  - Tier 5: much bigger bonus, real (moderate) trade-off.
  - No Movement is ever a pure upgrade at any tier — trade-offs stay meaningful at max skill.
- Movement axes (v1): charge economy (`maxCharge`, `rechargeRate`, manual-wind calc cost/efficiency) and effect amplification. Movements never touch complication capacity (see below) or the 2nd-slot milestone.
- **Passive ore-type efficiency bonus** is driven **only** by the Movement's attuned ore type — never by what's currently loaded in the complications. (Loadout-driven would be trivially gameable via pre-action swap-in/swap-out; Movement-driven keeps it a strategic, rare choice.) Flat additive bonus to the relevant success-chance formula (`cultChance`, `craftChance`, `seedSuccessChance`, and future discovery/refine chance once M3 ships) when the action's ore type matches the attunement; magnitude scales with Movement tier.

## Charge model

- Persistent `currentCharge`/`maxCharge` pool — **not** a full daily reset (departs from the old `chargesPerDay`/`chargesUsedToday` model).
- Natural regen: `rechargeRate` (charges/day, possibly fractional) ticks on the daily cycle.
- **Manual recharge is winding.** Spend calc outside combat to add charge faster. Calc type is always the Movement's attuned ore type (re-seating a different Movement changes the fuel type going forward). Exact cost formula: TBD. See §Winding.
- Charge is read off the Dial as a **power reserve** — the real horological complication (*réserve de marche*) that shows how much winding is left in a mainspring. This is the reading, not a HUD element bolted on. See §The Collar.
- Dial leveling (XP, existing `DEVICE_XP_LEVELS`-style table) grows **both** `maxCharge` and complication capacity as the primary curves, with `rechargeRate` growing on a slower/occasional curve (bigger stat grows every level; rarer stat grows every few levels) — reads as "bigger reserve now, refills faster as a rarer milestone."

## Complications (loadout)

- No separate "artefact" item category / no duplicate crafting list. **Existing consumable recipes are loaded directly into the Dial.**
- Loading is non-destructive: moves one unit from the tiered inventory bucket (`Crafting.inventory` shape, §2) into `device.loadedItems`, preserving its crafted tier/quality. Unloading reverses this — back to inventory, unconsumed.
- Casting a loaded complication spends a **charge**, not the item. The same recipe used the old way (thrown directly in combat, sold to Archie) still destroys a unit on use, exactly as today — destruction-on-use stays exclusive to that path.
- Capacity is a **numeric budget** (`capacityUsed <= capacityMax`), not discrete typed/shaped sockets. Each recipe has a **fixed** capacity cost (e.g. Blast=3, Time Pearl=1, Shield=2) regardless of crafted quality tier — quality only scales `effectPower`, never footprint (so better crafting is never a downside).
- Capacity grows with Dial **level only** — Movements never modify it (kept separate from the 2nd-Movement-slot milestone, which also isn't a capacity mechanic).
- Physically, capacity is **the number of detents on the Dial**, and it is countable by eye rather than stated as a number (§The Collar).

## Casting / combat

The fiction: a Movement can hold and shape a charge but cannot release one cleanly. Discharge needs a straight rigid channel — the barrel — to run down before it leaves at the ferrule. That is what the haft is for, and it is why a Dial fitted to something pocket-sized does not work at all (§Hafts).

- Sequence: **turn** the Dial to the complication, **press the catch** to release. Two beats, deliberate.
- Base effect = `effectPower` at the loaded unit's crafted quality tier (existing formula, unchanged).
- Dial/Movement amplification layers on top of the base effect (damage amplification, frozen-turns duration, effect breadth/number of targets, etc., per archetype). Exact amplification formulas: TBD.
- Directly-used consumables (not loaded into the Dial) get no amplification — same as today.
- **Turning the Dial is free.** Selecting a complication does not cost a combat action or a charge; only the catch spends charge. Charging for menu navigation is a tax, not a decision.

## Hafts

The Dial does not work on its own. It has to be fitted to something with a barrel.

- **Minimum barrel length, and no gradient above it.** Below the minimum a Dial will not discharge at all. Above it, nothing changes — a full-length shooting stick and a telescopic baton perform identically. Barrel is a **gate, not a stat**.
- Practical minimum is roughly forearm length. This is why a Dial cannot be fitted to a wristwatch, a ring, or a lighter: those can hold a Movement and hold charge, but have nowhere for a discharge to go.
- **Hafts are cosmetic.** No combat stats, no narrative effects, no reputation or negotiation modifiers. What you are carrying is never read by an event or an opener. A haft is flavour and identity only.
- Hafts are mundane objects and are freely swapped. Losing one costs nothing; losing the Dial is the disaster.

### What this buys, for free

Because every practitioner needs at least a forearm's length of rigid channel, everyone in the trade is visibly carrying something long and boring. The "practitioner's mark" is not a symbol — it is a **silhouette**, hiding in the single most over-populated object category in Britain.

> *Flavour, draft, PROSE-REVIEW:* Umbrellas on dry days. A man on the Jubilee line with a snooker cue and no case. Once you know, you cannot stop seeing it.

### Faction hafts

Cosmetic identity only. Drives art, not maths.

| Faction | Haft | The tell |
|---|---|---|
| **The Collective** | Mismatched, secondhand, mended. Market-stall brollies, a cane with a new ferrule | Someone else's initials on the collar. They get lent out and come back |
| **The Firm** | Issued telescopic steel batons, identical, numbered. Seniors carry inherited shooting sticks | Uniformity. "Old money, new methods" in one object |
| **The Guild** | Made, not repurposed. Black silk, hand-turned malacca, in-house collars | No maker's mark. Everyone who matters already knows |
| **The Network** | No house style, deliberately. A monopod at a press call, a rolled site plan in hi-vis, a cue in a pub | The haft always matches the room. That *is* the tell, once you notice |
| **The Conclave** | Full-length, obviously old, has never collapsed and never will. Bronze ferrule, worn crook | They carry it indoors and nobody asks them to leave it at reception |
| **Street / unaffiliated** | Scaffold pole, snapped cue, car aerial with a collar cable-tied on | It works. Not always on the first press |

## The Collar — UI widget

One widget, two modes, sited in the bottom ~110px of the screen where a thumb already is. The Dial is a round collar seated around the top of the haft's handle; the widget renders the handle in perspective with the near arc of the collar facing the player, so the ring reads as round while the interaction stays a flat horizontal swipe.

### Reading it

- **Index mark** fixed dead centre. The collar rotates, the mark does not — how a real dial reads, and it keeps the selected complication in one screen position.
- **Detents**, one per capacity point. Each shows the loaded complication's glyph, its tier pips, and a low glow in its ore colour. Empty detents are machined-blank. Capacity is counted, not stated.
- **Power reserve** above the collar: pips totalling `maxCharge`, filled to `currentCharge`, in the Movement's attuned ore colour.
- Never colour-only: glyph and tier pips carry all information independently of hue.

### Turning it

- Horizontal drag, snapping to detents.
- **Light haptic tick per detent**; a distinct heavier **end-stop** at each end.
- **No wrap-around** (proposed). Hard stops give the collar a felt extent, so positions become muscle memory and you cannot overshoot past your last complication into your first mid-fight. Noted as slightly in tension with the collar being physically round — a stop pin covers it, but it is a UI decision worth confirming on device.

### Firing it

- **The catch**: a thumb affordance at the right of the collar, where an umbrella's spring catch sits. Turn to select, press to release.
- **Dead catch on insufficient charge**: the catch depresses with a dull heavy haptic and does not release. No modal, no toast, no red text. The object reports its own state.

### Load mode

The same widget, in HQ → Practice and the BagDrawer. Tap an empty detent → inventory picker filtered to loadable recipes. Tap a filled detent → unload. Identical scene, identical system calls — satisfies the "both surfaces, one implementation" rule in §UI / navigation.

### Flavour beat

> *Flavour, draft, PROSE-REVIEW:* The click is audible. In a quiet room, the person opposite hears you selecting. Arming is never free of the social cost of arming.

### Technical risk — haptics

The widget's satisfaction rests almost entirely on per-detent haptic feedback. Godot's built-in handheld vibration API is duration-based rather than a fine-grained taptic engine interface, and fidelity differs between Android and iOS; crisp per-detent ticks on iOS may require a plugin. **Recommend a short on-device spike before designing further around the feel** — if the ticks cannot be made crisp, the widget needs a visual/audio fallback designed in, not retrofitted.

## UI / navigation

- HQ is being restructured into three sub-sections: **Lab** (crafting/recipes/experimenting), **Facilities** (rooms/security/property tier — old `property`), **Practice** (skill training [not yet built] + houses the Dial). "Practice" chosen over "Discipline"/"Conditioning" (too martial/gym-only) or "Development" (reads corporate-HR, risks a wink) — a real trade word covering both ongoing training and instrument upkeep.
- **Creation** (seeding the Dial, crafting a Movement) lives in HQ → Practice — a workbench-style, deliberate action, matching how big one-time crafting investments already work.
- **Day-to-day management** (swapping Movements, loading/unloading Complications, changing haft) is available from **both** the global BagDrawer (matches existing weapon-equip / old device build-attempt-abandon pattern, reachable mid-run from anywhere) **and** HQ → Practice (so a new player can load Complications immediately after crafting, without leaving HQ). Both surfaces render the same Collar widget in Load mode and call the same underlying system functions — no duplicated logic.
- **Onboarding is narrative, not a standalone tutorial event**: Dial-seeding is built into **The Collective Act 2** questline, not a generic post-tutorial unlock. Archie points the player to James for an edge against The Firm; reaching a James-relation threshold (exact number owned by the Act 2 quest spec, not this doc) unlocks asking him about it; James finally says what he noticed in the tutorial (§The gift), teaches Dials, and helps seed the player's first one. No separate `dialUnlocked`-style onboarding event needed outside that quest.

## Movement archetypes (v1 launch set: four)

Each has its own tier-scaled bonus/downside curve (per §Movements); the *defining* trait below is specifically a **top-tier (tier 5)** payoff, not present at lower tiers — lower tiers just lean numerically toward the same axis without the qualitative shift.

- **Recharge** — biases `rechargeRate` up, `maxCharge` down. **Top-tier defining trait: in-combat regen** — the charge pool passively ticks up during a fight itself (e.g. +1 charge every N player turns), the only archetype whose top tier changes *when* charge regenerates (every other Movement only recharges between fights/via winding). Identity: very few charges, but effectively self-sustaining if paced.
- **Capacitor** — biases `maxCharge` way up. **Top-tier defining trait: zero natural `rechargeRate`** — charge only ever comes from winding, never from time passing. Identity: huge reserve, but must be actively fed or it stays empty.
- **Impact** — biases raw effect magnitude (damage/heal amount/freeze duration) up, steepest `maxCharge` penalty of the amplify pair. Purely numeric, no qualitative top-tier hook — the archetype's whole appeal *is* the raw number. Identity: a small number of devastating single-target casts.
- **Spread** — extends a normally single-target effect to hit/heal multiple targets, **at full power per target, no dilution** (splitting power across targets would make it strictly worse than Impact for the same charge cost, defeating the point). Cost lives entirely in charge economy, not in diluted output. Exact extra-target count by tier: TBD, balance pass later. Identity: fewer casts, but each one covers the whole fight.

No archetype is ever a pure upgrade at any tier (per the tier-ramp rule) — all four keep a real trade-off even at tier 5.

### Horology mapping (art/flavour direction, no mechanical change)

The four archetypes map onto real watch movement types closely enough to drive naming and art without inventing anything:

| Archetype | Real movement | Fit |
|---|---|---|
| **Recharge** | Automatic / self-winding — a rotor that winds from the wearer's motion | Exact. Its top-tier "regenerates mid-fight" trait becomes literal: you are moving, so it is winding |
| **Capacitor** | Manual-wind with an oversized mainspring barrel | Exact. Enormous reserve, no rotor, zero natural rate |
| **Impact** | Striking movement / repeater — movements with actual hammers in them | Good |
| **Spread** | Regulator — indications spread across separate subdials | Weakest of the four; an honest stretch, flagged rather than forced |

## Winding (manual recharge)

- **Instant, no time-block cost** — unlike Seed/Cultivate/Prune (each 1 block), winding the Dial is a free background action, calc-cost only. Keeps it from competing with the game's other core loops for the scarce 3-blocks/day resource.
- Calc cost is always the currently-seated Movement's attuned ore type.
- Cost-per-charge depends **only on Movement archetype + tier**, never on the Dial's own level/`maxCharge` size — Capacitor's tier ladder naturally includes the cheapest winding rate (its whole reason to exist); other archetypes pay a pricier "backup" rate. Independent of level so progression never makes the mechanic worse.
- No artificial daily cap beyond ore affordability (ore scarcity is the real constraint, same as every other calc-gated action in the game).

## Open items

**Design decisions needing sign-off (not numbers):**
- The supply problem — does a Dial bind to a person present at its seeding? (§The gift). Blocks any faction/quest writing that touches Dial provenance.
- Collar wrap-around vs. hard stops (§The Collar). Confirm on device.
- Haptic fidelity spike (§The Collar) — may force a fallback design.

**Numbers only — shape is decided:**
- Exact bonus/downside numbers per archetype per tier (needs balance sign-off, same status as every other undertuned formula in REFERENCE.md).
- Exact winding calc-cost-per-charge numbers per archetype/tier.
- Exact Spread extra-target count by tier.
- Exact seeding base-cost numbers (the multi-ore-type, life-weighted mix) and Movement recipe ingredient costs.
- Minimum barrel length as a concrete value, if it is ever expressed numerically rather than as a haft whitelist.
- State schema: how `player.equipment.device` and `devicesInProgress`/`devicesCompleted` get replaced — almost certainly a single `player.device: {...} | null` object (Dial), plus its seated Movement, `loadedComplications` list, and a cosmetic `haftId`, but not yet drafted field-by-field. Deferred to implementation-planning time, not a design question.

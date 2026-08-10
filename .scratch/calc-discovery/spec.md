# M3 — Calc Effect Discovery ("The Lab")

Status: `ready-for-agent`

Source vision doc: `docs/M3-CALC-DISCOVERY.md` (all numbers there are PROVISIONAL; this spec promotes the mechanics and schema to build-ready status but tuning constants stay tunable — see Further Notes).

## Problem Statement

Players craft calc consumables and passives from recipes, but today every recipe a player will ever have access to is either already known or locked behind an NPC scene — there's no way to go looking for new ones. The human wants a bench mini-game where players combine orichalchum types and physical techniques to discover new calc effects for themselves, discovery-as-play rather than discovery-as-being-told. The hard constraint on the design: a player poking around the bench must never be left wondering *"is there anything left to find here, or am I wasting ore going back to this pairing?"* — that specific frustration has to be structurally impossible, not just rare.

## Solution

A new HQ feature, **the Lab**, sits alongside the workbench and gym. The player picks one or two orichalchum types and a physical approach (heat, grinding, compression, distilling — the last two gated behind home rooms) and spends ore plus a time block to run an experiment against that pairing. Every experiment resolves the truth of what's there: if the pairing+approach cell is empty, the player learns that permanently ("inert"); if it's occupied and the roll fails, the player is told plainly that something is there and gets a permanent pity bonus on their next attempt ("hot"); if the roll succeeds, the effect is discovered and immediately craftable as a normal recipe. The first probe of any type pairing also surveys it, permanently revealing how many effects it holds in total — including ones behind approaches not yet learned — so the player always knows whether more is out there, at the cost of one experiment. No effect is ever behind a hard skill gate; skill only moves the odds. Discovered effects can be re-experimented to refine them through uncapped tiers at rising cost and falling (but floored) odds. Effects can also be taught directly by NPCs, but every taught effect also lives in a real, discoverable cell — teaching is a shortcut, never an exclusive channel.

## User Stories

### Core probing loop

1. As a player, I want to pick one or two orichalchum types at the Lab, so that I can choose what pairing to experiment on.
2. As a player, I want to pick a physical approach for my chosen types, so that I can attempt an experiment on a specific cell.
3. As a player, I want to see the ore cost, time-block cost, and success odds before I confirm an experiment, so that I can decide whether it's worth it.
4. As a player, I want my ore spent whenever I run an experiment regardless of outcome, so that the cost is consistent and I'm not tempted to save-scum a "free" probe.
5. As a player, I want a single time block consumed per experiment, so that experimenting competes with the rest of my day like every other activity.
6. As a player, I want an outcome-agnostic animation while the experiment resolves, so that I can't read the result before it lands.
7. As a player, I want a skippable animation, so that repeated experimenting doesn't waste my time once I've seen it.
8. As a player, when I probe an empty cell, I want to be told plainly that there's nothing there and that this is permanent, so that I never waste ore returning to it.
9. As a player, when I probe an occupied cell and fail, I want to be told plainly that something is there, so that I know it's worth coming back rather than wondering if I imagined a lead.
10. As a player, when I probe an occupied cell and succeed, I want the effect's name, symbol, and what it does shown immediately, so that the discovery feels like the payoff it is.
11. As a player, I want every failed attempt on a cell to make my next attempt on that same cell more likely to succeed, so that persistence is always eventually rewarded.
12. As a player, I want the odds shown on the confirm screen to already include my accumulated pity bonus, so that I can see the number climbing across visits as proof the mechanic is working.
13. As a player, I want my crafting skill and workshop bonus to affect discovery odds the same way they affect regular crafting odds, so that the Lab feels like part of the same game as the workbench.
14. As a player, I want low crafting skill to mean long odds rather than a locked door, so that I'm never told I can't attempt a cell — only that it'll take longer.

### Honesty / cell state

15. As a player, I want every cell I've interacted with to show its state in plain words (not a glyph or color-only code) wherever I'm looking at that pairing, so that I never have to remember or guess what I already learned.
16. As a player, I want cells I've already emptied out (inert) to be visibly dimmed and untappable, so that I structurally cannot waste ore repeating a dead experiment.
17. As a player, I want cells I haven't tried yet to show no subtitle at all, so that "untried" reads unmistakably differently from every other state.
18. As a player, I want approaches I haven't learned yet to show where I can get them (a room, a contact), so that a locked row reads as a goal rather than a dead end.
19. As a player, I want the first experiment I ever run on a given pairing to reveal, permanently, how many effects that pairing contains in total, so that I know up front whether it's worth coming back after I get one thing out of it.
20. As a player, I want that reveal to count effects hidden behind approaches I haven't learned yet, so that learning a new approach later feels like unlocking a known reward rather than a surprise.
21. As a player, I want the pairing's "how much is left" information delivered as a sentence in normal play, so that it doesn't read like a stat sheet.
22. As a player, I want the exact numeric count available somewhere if I go looking for it, so that players who want to plan precisely aren't blocked from doing so.
23. As a player, I want a pairing with genuinely nothing in it to say so flatly on my first probe, so that "barren" and "not yet surveyed" never look the same.

### Approaches

24. As a player, I want to start the game already knowing Heat and Grinding, so that the Lab is usable from day one.
25. As a player, I want Compression to unlock via a specific home room, so that upgrading my property has a mechanical payoff at the bench.
26. As a player, I want Distilling to unlock via a later home room, so that there's a late-game approach gate to work toward.
27. As a player, when I learn a new approach, I want a notification, so that I know the moment it happens.
28. As a player, when I learn a new approach, I want every pairing I've already surveyed to visibly refresh if it still has unknowns, so that I immediately understand what just opened up for me.

### Refinement

29. As a player, I want to re-experiment an effect I've already discovered, so that I can push it to a higher tier.
30. As a player, I want refinement's ore cost to rise with each tier, so that pushing a favourite effect far is a real, escalating investment.
31. As a player, I want refinement's success odds to fall with each tier but never hit zero, so that there's always a nonzero chance, and always a point where it stops being worth it.
32. As a player, I want refinement tiers to be uncapped, so that a rich, high-skill player always has somewhere further to push a favourite effect.
33. As a player, I want each effect's per-tier gain (healing amount, freeze duration, passive duration, etc.) to be defined for that specific effect, so that refinement means something different and appropriate for each effect type.
34. As a player, I want inert cells to never be refinable or retriable through any mechanism, so that "inert" always means permanently dead.

### UI structure

35. As a player, I want to reach the Lab from HQ as a card alongside the workbench and gym, so that it fits where I'd expect a bench activity to live.
36. As a player, I want the Lab home screen to show what I've found and what approaches I know, never a list of what I'm missing, so that the screen reads as a trophy shelf, not a checklist.
37. As a player, I want to tap a found effect from the Lab home screen straight into its pairing panel, so that revisiting an effect to refine it is quick.
38. As a player, I want to pick my types from a plain list of the 5 orichalchum types with quantities I'm holding, so that I can see immediately whether I can afford to work with a given type.
39. As a player, I want the type picker to show no census, state, or progress information, so that it stays a simple materials list and doesn't turn into a de facto grid of all 15 pairings.
40. As a player, I want the pairing panel to show every approach row's state inline (found/hot/inert/untried/unavailable) in one place, so that I have everything I need to decide my next move without extra taps.
41. As a player, I want a separate, opt-in "bench notes" screen listing only the pairings I've actually touched, with numeric counts and a short history per pairing, so that I have a record to plan from without the game ever handing me a checklist of the untouched pairings.
42. As a player, I want bench notes entries to be capped (oldest dropped) per pairing, so that a heavily-experimented pairing's history doesn't grow unbounded.
43. As a player, I want the Lab to never show the 15 type-pairings as an explicit grid, matrix, or completion tracker anywhere in the game, so that exploring the bench always feels like poking at something rather than filling in a table.

### Data / systems integration

44. As a player, I want effects I've already discovered before an NPC offers to teach them to acknowledge that fact in the NPC scene (never silently grant nothing), so that my own discovery work is respected by the story.
45. As a player, I want an NPC teaching me an effect to grant it instantly with no ore or time cost, so that being taught genuinely feels like a shortcut relative to experimenting.
46. As a player, I want the three tutorial-granted consumables (Time Pearl, Enhancement Powder, Rewind) to already show as found on my first Lab visit, so that the found list isn't empty and I can see how a discovered effect is presented before I've discovered anything myself.
47. As a player, I want my Lab progress (approaches, surveyed pairings, cell states, notes) to survive a Rewind exactly as it was, so that using the game's flagship time-travel feature never un-discovers something I found.
48. As a player, I want a Lab session interrupted by app close/reopen to resume correctly (no double-charge, no lost state), so that the feature is as reliable as the rest of the game's persistence.

## Implementation Decisions

### Data schema

- **`data/approaches.json`** (new file): one entry per approach — `heat`, `grinding`, `compression`, `distilling` — each with `name`, `symbol`, and `source` (`{"type":"start"}` or `{"type":"room","id":"..."}`; schema also tolerates `{"type":"contact"|"faction"|"device", ...}` for future approaches, unused at launch).
- **`data/recipes.json` migration** (no parallel effects file — a discovered effect *is* a recipe):
  - `ingredient: "time"` (singular string) → `ingredients: {"time": 5}` (dict). This is a breaking schema change touching `systems/crafting.gd`, `systems/devices.gd`, `systems/rooms.gd` (lab room's auto-craft), `scenes/screens/hq.gd`, and `REFERENCE.md` §1.3. Mechanically neutral for all existing recipes (single-key dict reproduces current behaviour).
  - `baseCalcCost` (single scalar) is superseded by per-ingredient cost. `Crafting.calc_cost()` must be re-expressed to compute cost per ingredient key in `ingredients`, preserving the existing `max(1, round(base − (skill−1) × 0.8))` shape per ingredient.
  - New optional field `discovery: { "types": ["life","time"], "approach": "heat" }` on any recipe that is reachable via the Lab. Absent `discovery` means the recipe is not Lab-reachable (should not occur for the launch catalogue — every effect in §11 of the vision doc gets one).
  - New optional field `refineStep: { "field": "effectPower", "add": 3 }` describing what a refinement tier does to the recipe, applied per-effect rather than via a universal formula.
  - Existing `timePearl`, `enhancementPowder`, `rewind` get real `discovery` cells plus a `taughtBy`/tutorial-grant marking so their Lab cells start `Found` rather than `Untried`.
- **Home room rename**: `data/home.json` room id `lab` (cost 15000, tier `compound`) renamed in display name only to **"Improved Lab"** to disambiguate from the bench's in-fiction name "The Lab" (`REFERENCE.md` update required alongside). Internal id/key stays `lab` — only the player-facing `name` string changes — to avoid touching save compatibility or other references to the room id.
- **Type-set key helper**: one shared function producing the canonical key — types sorted alphabetically, joined with `+` (`"life"`, `"life+time"`, never `"time+life"`). All cell/census/notes lookups go through this helper; no inline key construction anywhere else.

### State schema

Added under `state.player.bench` (pure data, no object references, survives snapshot/Rewind):

```
player.bench: {
  approaches: ["heat", "grinding"],
  surveyed:   { "life+time": 3 },
  cells: {
    "life+time|heat":        { "state": "found", "misses": 2, "refine": 1 },
    "life+time|compression": { "state": "hot",   "misses": 3, "refine": 0 },
  },
  notes: { "life+time": [ { "day": 9, "approach": "heat", "outcome": "found" } ] },
}
```

- Cells are written lazily; an absent key means `untried` (state default, keeps saves small).
- `notes` entries store an outcome **enum**, never prose — prose for both notes and result cards is generated at render time from stored data, so wording can change without a save migration.
- `notes` arrays capped at ~20 entries per set, oldest dropped on append.
- Navigation state `state.benchNav: { view: "home", types: [], approach: null }` (view ∈ `home | picker | pairing | notes`) lives at the top level of `state` alongside `mapNav`/`phoneNav`, is transient, and resets on load — same convention, not persisted meaningfully across sessions beyond the current screen position.

### Systems

- **`systems/bench.gd`** (new, static funcs only, mirrors `systems/crafting.gd`'s shape): cell state resolution, type-set key construction, census computation/write, probe roll (discovery chance formula, pity application, ore deduction, XP award, cell state write, note append), refinement roll (separate chance/cost curve, tier increment), and `Bench.grant_effect(id) -> enum` — the single shared entry point NPC/faction content calls to teach an effect, returning an enum (e.g. `GRANTED`, `ALREADY_KNOWN_TAUGHT_APPROACH`, `ALREADY_KNOWN_XP_FALLBACK`) that event prose switches on for the collision cases in vision-doc §12.1.
- Discovery chance, pity, and refinement-chance formulas per vision-doc §7 (provisional constants — see Further Notes) live in `bench.gd`, mirroring `craft_chance()`'s shape (`Home.get_workshop_bonus()` reused as-is, no second bonus channel).
- Ore is always deducted on a probe or refinement attempt regardless of outcome, matching `Crafting.attempt_craft()` and `Cultivating.seed()` precedent.
- `Home.get_workshop_bonus()` is reused unchanged for discovery/refinement odds — no new bonus channel introduced by this feature.

### UI

- HQ gets a third card (`scenes/screens/hq.gd`) for the Lab, alongside workbench and gym, in-fiction-named "The Lab".
- New screens, each a `ScrollContainer` of `UI.card()` rows (no new custom widgets), navigated via `state.benchNav`:
  - **Lab home**: found-effects list (tap → pairing panel), known-approaches sentence, entry points to "Run an experiment" and "Bench notes".
  - **Type picker**: flat list of the 5 types with ore-held counts, tap-to-select up to two, no state/census columns.
  - **Pairing panel**: prose census line + one row per approach with inline state text, dimmed/untappable for spent, blank subtitle for untried, source text for unlearned.
  - **Confirm/result**: cost + block cost + odds (pity-inclusive) using `UI.format_cost_label`/`UI.format_block_cost_label`; one outcome-agnostic animation; one line of outcome prose per §8.4 register.
  - **Bench notes**: only touched pairings, numeric census, capped history list, prose generated at render time from stored enums.
- The 15 type-sets are never enumerated as a matrix, list, or completion tracker anywhere in these screens (standing constraint, not just a home-screen rule).

## Testing Decisions

Good tests here assert observable behaviour against `GameState.state` and rendered screen content — never internal formula intermediates or private helper structure.

- **`tests/test_bench.gd`** (new, primary seam, mirrors `tests/test_crafting.gd`): cell-state transitions (untried → inert/hot/found), the inert-is-permanent-and-unrollable invariant, pity accumulation and its effect on subsequent odds, census correctness (including approaches not yet learned counted), refinement tier/cost/odds progression, ore-always-deducted on every outcome, `Bench.grant_effect()` return-enum branches for the three §12.1 collision cases, and the canonical type-set key helper (alphabetical sort, `+`-joined, both input orders normalize identically).
- **`tests/test_crafting.gd`** (existing, extend): `ingredient` → `ingredients` migration is mechanically neutral — existing recipes still cost and craft identically pre/post migration; `calc_cost()` produces correct per-ingredient costs.
- **Screen tests** (new, mirror `tests/test_map_screen.gd`'s headless-scene pattern): Lab home card renders found list and approach sentence correctly; type picker enforces max-2 selection and toggle-replace behaviour; pairing panel renders correct state text per cell state (spent rows untappable, untried rows blank, unlearned rows show source) without a glyph-only encoding; bench notes only lists touched pairings and respects the ~20-entry cap.
- **`tests/test_snapshots.gd`** (existing, extend): explicit case asserting `player.bench` round-trips through a snapshot/Rewind unchanged — an already-discovered effect must not revert to `untried` or `hot` after a Rewind.
- **`tests/test_home.gd`** / **`tests/test_rooms.gd`** (existing, extend as needed): Compression/Distilling approach unlock resolution tied to room ownership; lab room display-name rename doesn't break existing room lookups by id.

## Out of Scope

- The ratio-axis input (mix ratio as a third axis) — considered and cut in the vision doc.
- Any screen enumerating all 15 type-sets as a grid, list, or completion tracker — standing constraint, not a phase cut.
- Triple-type sets in the UI or launch data (schema tolerates an array of types; only single/pair are authored or exposed).
- Minor Incidents / injury on failed probes.
- Bought recipe fragments and the Soho marketplace (M4).
- Affinities (`VISION.md` §5b) — noted as a future modifier on discovery odds, not designed here.
- Any change to crafting resolution itself beyond the `ingredients` schema migration.
- Calcining and Quenching approaches (cut from launch roster; schema-compatible if added later).
- Authoring the actual James/faction NPC teaching scenes and their content — this spec covers the `Bench.grant_effect()` mechanism and collision-handling contract those scenes must call into, not the scene content itself.
- Populating `data/recipes.json` with the full §11 effect catalogue's prose/descriptions beyond what's needed to demonstrate the schema — bulk content authoring is a separate content pass (ticket 10 in the doc's §16 shape) and needs its own `PROSE-REVIEW`.
- Final balance/tuning of the §7 provisional numeric constants (see Further Notes).

## Further Notes

- All numeric constants (discovery-chance formula, pity increment, refinement-chance floor, ore costs, XP rewards) in vision-doc §7 are explicitly **provisional tuning targets, not canon** — implement them as specified so the system is fully functional and testable, but expect a dedicated balance-pass ticket (§16 item 12) to adjust the constants post-implementation without further schema or architecture changes.
- Open question left unresolved by design (vision-doc §15 Q6): with no index of the 15 pairings ever shown, players may report feeling lost rather than curious. The documented cheap mitigation if this surfaces in playtest is a single aggregate line on bench notes ("you've worked 6 pairings") without ever naming the untouched ones — flagging here so it isn't lost, not committing to build it now.
- Prose (approach names/flavour, all cell-state and result strings, bench notes lines) is new and needs `PROSE-REVIEW` against `docs/CONTENT-GUIDE.md` per the vision doc's own flag — carry that flag into whichever ticket writes the actual strings.
- This spec corresponds to vision-doc §16's dependency-sorted ticket list (approaches/rename → ingredients migration → state shape → bench.gd core → refinement → benchNav/HQ card → picker/pairing panel → confirm/result → notes screen → content pass → grant_effect/collision wiring → balance pass). Ticket breakdown into `.scratch/calc-discovery/issues/` should follow that order — each ticket depends on the ones before it landing.

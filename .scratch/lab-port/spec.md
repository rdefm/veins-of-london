# Lab port — the perform-to-master bench becomes the live Lab

Status: ready-for-agent

Builds on: `.scratch/lab-revamp/spec.md` (prototype, Slice A "Procedure" with freeform runs and experimenting clues — the chart slice was removed). Must deliver every check in `.scratch/recipe-acquisition/spec.md` § "Prerequisites from the bench port" (P1–P4); those are restated below as acceptance criteria.

Save compatibility: not required.

## Problem Statement

The live Lab bench is a lottery: tap an ore set and an apparatus, roll for a recipe, then roll again until the tier reaches 5. There are no decisions, no skill expression and no reason to come back. The perform-to-master prototype (procedure steps on gauges, hints, experimenting clues, ranks) played better, but it lives in a Debug-only sandbox with its own calc, its own ranks and only 3 recipes. The real game still crafts through the lottery.

## Solution

The prototype becomes the live Lab, replacing the lottery bench entirely:
- The Lab plate and the recipe book are the only crafting interface.
- You know recipes (from story and, later, from sellers). Each recipe has an authored procedure you perform by hand on four apparatus gauges, using your real calc.
- Your score sets the recipe's rank (1–5), and the rank is the tier of the items you make.
- Hints and experimenting reveal hidden steps that raise the best rank you can reach.
- Once you've performed a recipe, you can batch it at your best rank.
- Every recipe in the game has a full four-rung procedure.
- Lab staff keep crafting on their own, at their own skill.

## User Stories

### Knowing recipes
1. As a new player, I want to start knowing no recipes, so that every recipe I learn is something I was given or earned.
2. As a player, I want meeting James to teach me the Time Pearl base procedure, so that crafting opens where the story opens it.
3. As a player, I want the recipe book to list only the recipes I know, filtered by ore tab, so that it reads like my own notebook.
4. As a player, I want each recipe page to show the procedure as I currently know it, so that I know what to do at the bench:
   - exact steps with their band;
   - vague steps as a faded region with a direction word;
   - unknown steps hidden.
5. As a player, I want each recipe page to show my best rank, so that I can see my mastery.
6. As a player, I want a space on the recipe page reserved for the knowledge ladder, so that later recipe sources slot in without a redesign.

### Performing a manual run
7. As a player, I want "Craft manually" on a recipe page to dock the book under the Lab plate with the steps I know, so that I can read the procedure while I work.
8. As a player, I want to tap ore jars to add that recipe's calc amount from my real stock, so that the calc I gathered is what I craft with.
9. As a player, I want only the recipe's own ore jars to be tappable during a run, so that I can't waste unrelated calc.
10. As a player, I want to tap any apparatus at any point in the run and perform its gauge, so that I can follow the book or experiment freely:
    - heat: hold, release in the band;
    - grind: stroke timing;
    - compress: hold, release in the band, overshoot cracks;
    - distil: drip timing.
11. As a player, I want steps to come in any order and repeat, so that experimenting is possible.
12. As a player, I want Finish to end the run and score it, so that I decide when I'm done.
13. As a player, I want overshooting a compress to crack the vessel and end the run with the calc lost, so that risk is real.
14. As a player, I want my score (0–100) to set the run's rank using the existing thresholds, so that execution matters.
15. As a player, I want the run to produce one item at the run's rank as its tier, so that a good run makes a better item.
16. As a player, I want my best rank per recipe to only ever go up, so that I keep my mastery.
17. As a player, I want a run at or above my best rank to sometimes roll a bonus, so that re-running by hand is occasionally rewarded. The bonus is drawn at random from: an extra item, half the calc refunded, or extra XP.
18. As a player, I want a really bad run to sometimes give a dry flavour line, so that failure has character.
19. As a player, I want my crafting skill to widen the tolerance bands, so that levelling up makes hard recipes doable.
20. As a player, I want my Workshop/Library, the Guild perk and my seated Dial Movement's attunement to widen the bands too, so that the bonuses I've invested in still matter.
21. As a player, I want an active Prophet's Breath to reveal the true bands and an active Be A Lady to add score, so that my consumables help at the bench as they did in the prototype.
22. As a player, I want manual crafting to cost no time blocks, so that the Lab stays a place I can spend time in freely.

### Experimenting and learning
23. As a player, I want each step to get a clue after Finish, so that I can deduce what to change:
    - ✓ in band;
    - ~ with a direction;
    - ✗ no effect;
    - "something changed".
24. As a player, I want an off-book step that matches a hidden step to become a vague hint, so that experimenting discovers new steps.
25. As a player, I want three in-band hits on a vague step to make it exact, so that I can master a step on my own.
26. As a player, I want hints from any source (story, debug, experimenting) to look and behave identically, so that knowledge is one consistent thing.

### Batch and auto-craft
27. As a player, I want to batch-craft a recipe I've performed at least once, at my best rank, so that I perform once and then produce at scale.
28. As a player, I want a batch to cost the base calc per item with no failures and no performance, so that auto-craft is a reliable reward for mastery.
29. As a player, I want the multi-target variant to become available once my best rank is 3+, so that the existing variant keeps its place.

### Rewind
30. As a player, I want to Rewind a run by spending a Rewind (an item or a loaded Dial complication), so that the bench follows the same Rewind rules as events and combat.
31. As a player, I want a Rewind to restore everything to just before the run, calc included, so that a botched run can be undone.

### Rewards and side effects
32. As a player, I want manual runs and auto-crafted items to award crafting XP (a cracked or abandoned run gives a third), so that crafting levels me up.
33. As a player, I want crafted items to count toward objectives, Collective missions, market shares and contracts exactly as before, so that nothing downstream breaks.

### Lab staff
34. As a player, I want Lab staff to keep crafting toward my Production targets, so that the Lab still runs while I'm away.
35. As a player, I want staff-made items' tier to come from the staffer's own crafting level, not from my recipes or my skill, so that hiring and training better crafters matters on its own terms.
36. As a player, I want staff never to make tier-5 items, so that rank 5 stays mine alone.

### Content
37. As a player, I want every one of the 17 recipes to have a full authored procedure, so that nothing is uncraftable at the new bench.
38. As a player, I want every recipe to have two hint rungs and a master rung of hidden steps, each lifting my ceiling by exactly one rank, so that every recipe has the same clear mastery path.
39. As a player, I want procedures fixed and the same in every playthrough, so that mastery knowledge is real.

### Removal and debug
40. As a player, I want the old lottery bench, with its cells, census, probes, survey notes and tier progress bars, gone, so that there's one way to craft.
41. As a designer, I want a Debug app Lab page with these tools, so that I can playtest the live bench quickly:
    - skill override;
    - grant or revoke recipes and hints at vague/exact;
    - refill calc;
    - set best rank.
42. As a designer, I want the sandbox prototype's screen and state removed once the live Lab replaces it, so that there's no duplicate code path.

## Implementation Decisions

### Module structure
- A new live **Lab system**, promoted from the prototype core, owns:
  - recipe knowledge;
  - procedure definitions;
  - the run lifecycle: begin, add ore, perform step, finish, crack, abandon;
  - scoring, clues and learning;
  - best rank, batch and the bench Rewind.

  It reads and writes the real game state, with no sandbox pool, sandbox ranks or sandbox ledger.
- **Crafting** stays the owner of inventory, tier buckets, effect power, XP, the multi variant and craft side effects (Objectives refresh, Collective missions and brief trigger, Shares, Contracts). Lab calls one Crafting entry point to file produced items, so the side effects fire for manual and batch alike.
- **Bench (lottery)** is deleted, along with its survey/notes state and the lab modals: confirm, probe result, notes, and the lottery-era recipe detail/craft flow. The approaches data is kept only as the apparatus list, with no cells. References in other systems (`item_tier`, `found_recipe_keys`, `grant_effect`) are replaced by Lab equivalents.
- **Rooms** (staff) keep their own crafting step. See Staff below.
- The **FactionSim** crafting curve is unchanged. Factions don't use the Lab.
- Prototype system, screen, data file and state key: removed after the live Lab lands. The prototype's debug back page becomes a Debug app Lab page.
- Dial Movement crafting is unchanged.

### State (pure tree)
- `lab` root:
  - `known`: `{ recipeKey: { steps: { idealIndex: "vague" | "exact" }, vagueHits: { idealIndex: n } } }`. Unknown steps are absent. The step-state set must be able to take one more state ("insight") without reshaping.
  - `bestRanks`: `{ recipeKey: 1..5 }`, only ever increasing.
  - `activeRun`: the current run or null. A run records its recipe, the calc spent per ore, the performed steps (apparatus, reading, ores added since the previous step), Lady/Breath state and its start.
  - `performedOnce`: a set of recipe keys. Batch needs the recipe in it.
- No sandbox `pool`, `snapshots`, `skillOverride` or `ledger`. The skill override is a Debug-only state field that is ignored when unset.

### Knowledge API
- `grant_recipe(key)` adds the recipe at base.
- `grant_steps(key, idealIndices, specificity)` grants hidden steps at a specificity. It upgrades vague to exact in place. A grant at a lower specificity than the step already has does nothing.
- `is_known`, `known_recipes(ore?)`, `known_procedure(key)` and `step_region` behave as in the prototype.
- Events reach this API through a new event op, `grant_recipe { recipe }`, plus `grant_recipe_steps { recipe, steps | rung, specificity }`. `james_meeting` swaps `craftingUnlocked` for `grant_recipe timePearl`. Anything that read `craftingUnlocked` (objectives, gates) reads "knows any recipe" or "knows timePearl" instead.

### Run rules (prototype rules carried over unless stated)
- Calc comes from the player's real unstashed orichalchum. A jar tap spends that ore's per-tap amount. All run calc spending goes through one function, so a later lesson session can swap in another source.
- Calc cost is **fixed per recipe**: base calc from the recipe's procedure data. Crafting skill no longer reduces calc cost. Skill widens bands instead, and the REFERENCE §3.5 cost formula is retired for the player.
- Tolerance: `band_half_width = baseTolerance × (1 + skillFactor × craftingSkill) × (1 + benchBonus)`. `benchBonus` is the sum of these, each converted from its old chance value by a factor in data:
  - the Home workshop/library bonus;
  - the Guild perk craft bonus;
  - the seated Movement's attunement bonus when its ore matches any ingredient.
- Scoring: the prototype's weighted accuracy, in-order matching, −5 per extra step, Lady score bonus, clamped to 0–100. Score maps to rank through the prototype's thresholds (data).
- There is **no success roll** for the player. A finished run always produces one item at its rank, unless it cracked or was abandoned (calc lost, no item).
- Re-run bonus: a run whose rank is at least the best rank rolls the bonus chance (data, 30%). On success, **one of the three types is picked at random**: +1 item, half the calc refunded, or XP ×1.5.
- Bad-run flavour as in the prototype (data lines, PROSE-REVIEW).
- XP:
  - a finished manual run awards the recipe's `xpReward` × the bonus multiplier;
  - a cracked or abandoned run awards ⅓;
  - batch awards `xpReward` per item.
- No time blocks spent.
- The manual-run hook: Lab emits one signal or calls one entry point per completed **manual** run, carrying `{recipe, score, rank, outcome: finished | cracked | abandoned}`. It never fires for batch.
- Prophet's Breath and Be A Lady: same behaviour as the prototype. Breath shows true bands; Lady adds score per item level. Both use the player's real active effects and real items.

### Batch
- Batch ×N needs the recipe in `performedOnce`. It crafts at the best rank, costs the base calc × N, and always succeeds.
- The multi-target variant is available when the best rank is ≥ 3. The existing `craftMulti` checkbox and `_multi` inventory key are kept.

### Rewind
- The bench Rewind follows the event/combat contract. It needs a Rewind point (a snapshot taken at the run's first jar tap) and either a `rewind` item or a loaded Dial Rewind complication, which it consumes.
- It restores `lab`, `player.orichalchum` and the active-effect state to the snapshot.

### Staff (Rooms)
- Staff keep their speciality-based recipe eligibility and Production targets, and keep their existing crafting chance roll.
- **The item tier is set by the staffer's own crafting level**, capped at 4, and is independent of the player's recipe knowledge, best ranks and crafting skill.
- The staff calc cost uses the same fixed per-recipe base calc as the player.

### Content (the P1–P4 prerequisites for recipe acquisition)
- **P1:**
  - All 17 recipes have an authored procedure in the prototype schema (`ideal` steps with apparatus/ore/target/weight summing to 100, `base` steps whose calc sums to base calc, `baseTolerance`).
  - Multi-ore recipes have every ingredient ore in `base`.
  - Content is fixed and provisional.
  - Procedure data lives in the live Lab data. Recipe ingredient amounts in recipes data are reconciled with each procedure's base calc, and one of the two is the single source.
- **P2:**
  - Every hidden step (any step in `ideal` but not in `base`) carries one rung tag: `hint1`, `hint2` or `master`. It either inserts a step or corrects a base step's target.
  - Every recipe has at least one step per rung.
  - With knowledge up to a rung, a perfect run at max skill scores within that rung's band: base 40–59, +hint1 60–74, +hint2 75–89, all 90–100.
  - The prototype's three recipes get master step(s) and rung tags on their existing hints.
- **P3:** covered by the State, Knowledge API, Run rules and Staff sections above. Item tier = rank. Manual-run hook. Single calc-spend function.
- **P4:** the recipe page has a reserved, empty ladder region.

### Screens
- The Lab plate and recipe book replace the lottery bench UI in the HQ Lab zone. They are built from the prototype's plate, jars, apparatus gauges, docked book, recipe page (rank, Craft manually, batch) and result/clue view.
- They show real calc counts on the jar badges.
- Screens only render and call Lab and Crafting functions.

### Docs
- REFERENCE.md: rewrite §3.5 crafting (cost, no chance roll for the player, rank = tier, staff tier, tolerance and bonus conversion) and retire the M3 discovery mechanics. Add the `lab` state paths to §2.
- CODEMAP: rows for the new Lab system, data, screens and Debug page. Delete the bench, prototype and lottery-modal rows.

## Testing Decisions

- Tests check behaviour through the highest seam: state before, call, state after, plus emitted signals. Don't test private helpers. Prior art: the bench prototype tests (system and screen), the crafting tests, the rooms and events tests.
- **Seam 1 — the Lab system (primary):**
  - Knowledge: grant, upgrade, no-downgrade, new game knows nothing, `james_meeting` grants timePearl.
  - Runs:
    - only the recipe's own jars spend real calc;
    - steps are recorded;
    - the score maths, in-order matching and extra-step penalty work;
    - the rank thresholds hold;
    - a finished run always yields one item at tier = rank;
    - a crack or abandon yields nothing and loses the calc.
  - Bonus: it rolls only at rank ≥ best, and all three types are reachable with the seeded RNG.
  - The tolerance formula includes skill and each bench bonus source.
  - Breath and Lady effects work.
  - Clues and learning: all four clue kinds, vague on a match, exact after 3 hits.
  - Batch: needs `performedOnce`, crafts at best rank, never fails.
  - The multi variant is gated at rank 3.
  - Rewind: refused with no item or complication; consumes one; restores calc and state.
  - The manual-run hook fires once per manual run and never for batch.
  - No time block is spent.
- **Seam 2 — Crafting (existing):** items filed through the Lab entry point fire the Objectives, Collective, Shares and Contracts side effects, and award XP, exactly once per item.
- **Seam 3 — Rooms (existing):**
  - staff tier = the staffer's crafting level capped at 4, independent of the player's best rank and skill;
  - speciality eligibility and targets are unchanged.
- **Seam 4 — the procedure content test:** for all 17 recipes, schema validity, rung tags (at least one step per rung), base calc matching the recipe ingredients, and a simulated perfect run at each knowledge level landing in its band (P2).
- Screen smoke test: the Lab plate builds with real calc, Craft manually docks the book, and Finish shows the result. Gauge feel is on-device QA.
- Delete the lottery-bench tests along with the lottery bench.

## Out of Scope

- Recipe sellers, prices, relation gates, insights, James's lesson, Wren, and the master-technique quests (recipe-acquisition spec).
- Dial Movement crafting and bench secrets.
- Catalysts and new apparatus.
- Faction crafting.
- Art beyond carrying over the prototype's plate, gauges and book.
- Save migration.

## Further Notes

- Procedure authoring for 14 new recipes plus master steps for all 17 is the biggest content task. Split it into content tickets by ore group (time/life, physics, emotion/fate, mixed) with the P2 content test in place first.
- All numbers are in data and provisional, tagged for balance:
  - bonus-conversion factors;
  - skillFactor;
  - bonus chance and types;
  - per-recipe base calc;
  - staff tier cap.
- New prose for review (PROSE-REVIEW): clue text and direction words for new gauges and steps, bad-run lines, and any recipe-page copy.
- Playtest questions:
  - Does fixed calc cost feel fair against the old skill discount?
  - Do the converted bench bonuses feel noticeable?
  - Is staff output useful at low staff levels?

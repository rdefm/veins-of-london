# Recipe acquisition — James's experimenting lesson, recipe sellers, knowledge ladder

Status: ready-for-agent

Depends on: the Lab revamp bench (perform-to-master, `.scratch/lab-revamp/spec.md`) being ported into the live bench before any ticket here starts. The port must already deliver everything in **Prerequisites from the bench port** below. If any item is missing, it goes back to the port, not into this spec's tickets.

Save compatibility: not required. Old saves may break.

## Prerequisites from the bench port

The bench port spec (not yet written) must deliver every item below. Each one is phrased so it can be copied into that spec as an acceptance check.

### P1 — A full procedure for every recipe

1. **All 17 recipes** in `data/recipes.json` have an authored procedure:
   - timePearl, enhancementPowder, rewind, healingSalve, blast, shield, blackHole, prophetsBreath, beALady, panic, panger, pandemonium, pansRapture, healingBurst, failsafe, rejuvenation, wormhole.
   - This includes the 14 the prototype doesn't cover. The prototype's 3 (healingSalve, timePearl, healingBurst) gain the master step(s) they currently lack (P2).
   - There is no recipe the live bench can't perform.
2. Each procedure uses the prototype schema:
   - `ideal` (the perfect procedure: apparatus, ore, target, weight; weights sum to 100);
   - `base` (the procedure known on acquiring the recipe; its calc sums to the recipe's base calc);
   - `baseTolerance`.
3. Multi-ore recipes (healingBurst, failsafe, rejuvenation, wormhole) need every ingredient ore somewhere in `base`, so the base procedure alone makes a valid item.
4. Procedures are authored, fixed content: the same in every save, never randomised. Numbers are provisional and tuned in playtest.

### P2 — Every hidden step is tagged with the rung that reveals it

5. Every `ideal` step that isn't in `base` is a **hidden step** and carries exactly one rung tag: `hint1`, `hint2` or `master`.
   - A hidden step either *inserts* a new step or *corrects* the target/amount of a base step. The prototype already supports both.
6. Every recipe has **at least one hidden step in each of the three rungs** (`hint1`, `hint2`, `master`). So each recipe has exactly two purchasable improvements (Hint I, Hint II) plus a master technique, each adding or adjusting one or more steps.
7. A rung can hold more than one step. Buying or granting a rung reveals all of its steps at once.
8. **Rank ceilings are enforced by the weights.** With only the knowledge up to rung *r*, played perfectly at maximum skill, a run's best possible score must fall inside that rung's rank band. Steps the player doesn't know are assumed not performed or performed at the base target. Using the prototype's rank thresholds:

   | Knowledge held | Best possible score | Rank reached |
   |---|---|---|
   | base only | 40–59 | 2 |
   | base + hint1 | 60–74 | 3 |
   | base + hint1 + hint2 | 75–89 | 4 |
   | all four rungs | 90–100 | 5 |

   If the thresholds change in the port, the bands change with them. The rule is "each rung lifts the ceiling exactly one rank, from 2 to 5".
9. The port ships a **headless test** that checks rule 8 for all 17 recipes. It runs a simulated perfect run at each knowledge level and asserts which band the score lands in. This test is the guard on all procedure content.

### P3 — Knowledge state and API

10. Recipe knowledge lives in the pure state tree, per recipe:
    - known or not;
    - for each hidden step: unknown / vague / exact.
    - (The insight state, "revealed: apparatus + position only", is added by this spec as a fourth step state. The port's representation must be able to grow one more state without a schema rewrite.)
11. **New game knows no recipes.** The old lottery discovery is removed.
    - `james_meeting` grants timePearl at base through a port-provided event op or system call: grant recipe, and grant step(s) at a given specificity.
    - That same call must be usable by this spec's `RecipeKnowledge` system.
12. Granting a step that is already vague, at exact, upgrades it in place. Granting at a lower specificity than the step already has is a no-op.
13. Experimenting works as in the prototype:
    - a performed off-book step that matches a hidden step makes that step vague;
    - three in-band hits on a vague step make it exact.
    - Debug-granted, experimented and (later) bought knowledge all display identically.
14. Per-recipe best rank (1–5) is stored and only ever goes up. Auto-craft/batch crafts at the best rank.
15. The **item tier of a crafted item = the rank it was crafted at**, for both manual runs and auto-craft. Inventory, combat, guard kits, factions and offers keep reading `tier`. This resolves the prototype's "rank → real item tier mapping" open point.
16. The port provides a hook, a signal or a single system entry point, that fires once per completed **manual** run. It carries the recipe, score, rank and success/failure, and never fires for auto-craft. This spec hangs the insight roll and the lesson goal on it.
17. All calc spending for a manual run goes through one function. That lets this spec swap in a session-scoped calc pool for James's lesson without forking the bench.
18. Crafting skill widens tolerance bands (prototype rule). Rank 5 is player-only. Staff item tier comes from the staffer's own crafting level, capped at 4. It is independent of the player's recipe knowledge, best ranks and crafting skill (see `.scratch/lab-port/spec.md` § Staff).

### P4 — Recipe book

19. Each known recipe has a page in the live lab recipe book showing:
    - the procedure as currently known: exact steps with their band, vague steps faded with a direction note, unknown steps hidden;
    - the best rank reached.
20. The page has a **reserved area for the rung ladder**, empty in the port. This spec fills it with owned/locked rungs, sources and the master pointer.

## Problem Statement

Recipes today are found by lottery at the Lab bench, and James hands over Enhancement Powder for free in `james_motion`. Once the bench becomes perform-to-master, the player needs:

- a tutorial that teaches experimenting and climbing a recipe's rank;
- a reason to go back to James and the Guild;
- a clear path to every recipe and to its higher ranks.

Right now nothing ties crafting depth to NPC or faction relations, so building relations doesn't help the player's craft.

## Solution

James already taught the Time Pearl. In a rewritten event (`james_experiment`) he shows you how to experiment toward a better pearl. You work at the bench, on his calc, until you make one at rank 3. Only then can you leave. When you ask about other recipes, he says he's an expert in time and life calc and will sell you those. For everything else he writes to the Guild of Applied Alchemists. His motive, hinted at but not explained: he wants you good enough to repair his Dial's Movement one day.

Registrar Wren then takes you on as a Guild **associate**. She sells recipes for every other kind of calc and offers assay commissions that build Guild relation.

Every recipe has a **knowledge ladder**:

- a base recipe;
- two hints, which you buy once the seller's relation gate is open;
- a master technique, which only a quest gives you.

Each step raises the highest rank you can reach. Everything on the ladder can also be found by experimenting. A rare, skill-scaled **insight** nudges a patient player toward the next step.

## User Stories

### James's experimenting lesson
1. As a player, I want James to point out that my Time Pearls are mediocre, so that I have a reason to learn to improve them.
2. As a player, I want James to explain that the same recipe can be crafted at higher ranks, so that I understand ranks before I need them.
3. As a player, I want James to give me one vague hint about the Time Pearl, so that I learn hints have to be interpreted.
4. As a player, I want to experiment at the bench until a manual run reaches rank 3, so that I earn my first improvement by doing it myself.
5. As a player, I want the lesson to use James's calc, refilled after every failed run, so that failing costs me nothing of my own while I learn.
6. As a player, I want the lesson to cost no time blocks, so that the tutorial doesn't eat my day.
7. As a player, I want to be unable to leave the bench until I succeed, so that the scene stays focused, with James watching.
8. As a player, I want James to sharpen his hint to exact after 3 failed runs, so that I can't get stuck.
9. As a player, I want James to talk me through it after 6 failed runs, so that even a struggling player finishes.
10. As a player, I want Rewind unavailable during the lesson, so that I learn to fail, adjust and retry.
11. As a player, I want to keep the pearls I make and the crafting XP I earn during the lesson, so that practice feels worthwhile.
12. As a player, I want the Time Pearl's first hint to stay in my recipe book after the lesson, so that I keep what James taught me.
13. As a player, I want to ask James about other recipes once I succeed, so that the conversation leads into the wider system.
14. As a player, I want James to say he only knows time and life calc and will sell me those recipes, so that I know what he offers.
15. As a player, I want James to offer to write to a Guild contact about other calc types, so that I know where the rest of the recipes are.
16. As a player, I want James to tell me to practise and improve, and to hint that he wants me good enough for something of his (his Dial's Movement), so that his motive is a hook for later.
17. As a player, I want James to stay the same dry, grudging man, still taking me on as an overflow assistant, so that his voice and the jobs he sends stay consistent.

### Knowledge ladder
18. As a player, I want every recipe to have a base procedure, two hints and a master technique, so that I can see a clear path to mastering it.
19. As a player, I want the base recipe to cap me at rank 2, Hint I at rank 3, Hint II at rank 4 and the master technique at rank 5, so that each step visibly raises my ceiling.
20. As a player, I want hints and techniques to add or adjust steps at specific targets in the procedure, so that knowledge changes what I physically do at the bench.
21. As a player, I want every rung discoverable by experimenting, so that a dedicated player can master a recipe without buying anything.
22. As a player, I want manual runs to sometimes give an insight pointing toward my next undiscovered rung, so that self-discovery has some guidance.
23. As a player, I want my insight chance to grow with crafting skill, so that getting better at crafting makes discovery easier.
24. As a player, I want an insight to tell me which apparatus and roughly where in the sequence, but not the target, so that I still have to find the right amount myself.
25. As a player, I want insights to cover only the next rung, so that discovery climbs in order.
26. As a player, I want insights possible for master rungs too, so that a purist can reach rank 5 without a quest, just slowly.
27. As a player, I want auto-craft never to give insights, so that performing by hand stays the way to discover things.
28. As a player, I want hints I buy or win from quests to be exact, so that paying for knowledge saves me the grind.
29. As a player, I want hints from experimenting and insights to start vague and become exact after 3 in-band hits, so that self-discovery works the same as on the prototype bench.
30. As a player, I want buying a hint I already hold as vague to upgrade it to exact, so that the purchase is never wasted.
31. As a player, I want the recipe book to show each recipe's rungs as owned or locked, so that I can see what I still have to learn.
32. As a player, I want a locked rung to show where it comes from ("sold by Wren", "needs Guild Partner"), so that I know what to work toward.
33. As a player, I want a master rung to show a cryptic pointer, or "???" if it isn't assigned yet, so that it stays mysterious but still invites me to look.

### Recipe sellers
34. As a player, I want to buy recipes from James through his contact card's Trade button, so that buying uses a menu I already know.
35. As a player, I want to buy recipes from Wren through her contact card's Trade button, so that both sellers work the same way.
36. As a player, I want these sellers to sell only recipes and hints, and to buy nothing, so that their menus stay simple.
37. As a player, I want a purchase added straight to the right recipe page in the lab, so that I can use it at once without managing a Bag item.
38. As a player, I want James to sell every recipe whose ingredients are only time or life calc, so that his expertise matches what he sells.
39. As a player, I want Wren to sell every recipe that uses any other calc (including mixed ones like Wormhole), so that the Guild covers the rest.
40. As a player, I want all base recipes buyable as soon as I've met each seller, so that the full roster is open early.
41. As a player, I want Hint I and Hint II to need a relation level before I can buy them, so that building relations deepens my craft.
42. As a player, I want a met gate to unlock only the right to buy, not the hint itself, so that cash still matters.
43. As a player, I want James's gates based on my relation with him, so that working for him pays off.
44. As a player, I want Wren's gates based on my Guild faction tier (Hint I at Friendly, Hint II at Partner), so that Guild standing has a concrete crafting reward.
45. As a player, I want the Guild's hint gates listed in its Benefits ladder in the Register, so that I can see what the next tier unlocks.
46. As a player, I want prices to be high (sell price × 10 for the base recipe, × 15 for Hint I, × 20 for Hint II), so that knowledge feels valuable: these people are training their own competition.
47. As a player, I want Enhancement Powder's base recipe priced cheaply, so that my first purchase from James is affordable and teaches the buying loop.
48. As a player, I want a discount of up to 20% from strong personal goodwill (James's relation, Wren's standing), so that a personal bond is worth something on top of the gate.
49. As a player, I want recipe prices unaffected by market swings or the Network's gouge, so that knowledge prices are predictable.
50. As a player, I want the Trade sheet to show owned rows as owned and locked rows with the reason and price, so that I can plan my spending.
51. As a player, I want the Guild Marketplace to keep selling goods as it does now, so that buying goods and buying knowledge are separate.

### Wren and the Guild
52. As a player, I want a message from Wren the day after James's lesson, so that the introduction follows on from his letter.
53. As a player, I want a Wren introduction event where she registers me as a Guild associate, not a member, so that full membership remains something to earn later.
54. As a player, I want Wren to explain what she sells, how relation unlocks hints, and that commissions build relation, so that I understand the Guild's loop.
55. As a player, I want Ingram to get one cold line during the introduction, so that the Guild's gatekeeper shows up early.
56. As a player who has already met Wren through faction messages, I want the introduction to acknowledge that in one line, so that it doesn't contradict what I've already seen.
57. As a player, I want Wren's placeholder intro replaced with real prose, so that she reads as a proper character.
58. As a player, I want repeatable assay commissions from Wren ("deliver N of a recipe at rank ≥ R by day D"), so that I have a crafting-focused way to build Guild relation.
59. As a player, I want commissions to pay cash plus Guild relation, so that they move me up the Guild tiers.
60. As a player, I want a commission's required rank to rise with my Guild tier, so that commissions keep pushing my mastery.
61. As a player, I want existing Guild relation sources (trade lanes, offers, gifts and so on) to keep working, so that the new loop adds to them rather than replacing them.

### Master techniques
62. As a designer, I want a quest event op that grants a recipe rung, so that any future quest can award a master technique (or any rung).
63. As a designer, I want a per-recipe table naming each master technique's source NPC or faction, with unassigned entries allowed, so that master quests can be written one ticket at a time.
64. As a player, I want master techniques unbuyable, so that rank 5 marks relationships and quests I actually completed.

### Integration
65. As a player, I want James's overflow jobs to unlock when I know Enhancement Powder, so that jobs still follow from the assistant deal.
66. As a player, I want the existing Archie → James message trigger to lead to `james_experiment`, so that the story beat lands where it does now.

## Implementation Decisions

- **Event rename and rewrite.** `james_motion` becomes `james_experiment`.
  - The new event keeps the same trigger: Archie's motion event queues a James pending message.
  - The pending-message kind and every reference to it are renamed to match.
  - Flag `jamesMotionEventSeen` becomes `jamesExperimentSeen`.
  - Flag `enhancementUnlocked` is removed. Jobs checks whether the player knows `enhancementPowder` instead.
  - Prose: keep the current assistant/overflow exchange, trimmed. Then add the experimenting lesson and the post-lesson recipe conversation. All new lines are PROSE-REVIEW, written to CONTENT-GUIDE.md and writing-guide.md.
- **Bench lesson session.** A new event card/op opens the ported bench in a **locked lesson session** for one recipe:
  - recipe = timePearl;
  - goal = a manual run at rank ≥ 3.
  - Calc comes from a session-scoped pool, separate from the player's ore stock. The pool is refilled to one run's cost after each failed run.
  - The session costs no time blocks.
  - Rewind is disabled for the session.
  - Items and crafting XP from every run go to the player as normal.
  - The session can't be dismissed and nav is disabled until the goal is met. Success then returns control to the event, which continues.
  - Escalation, counted on failed runs (thresholds in data):
    - after 3, the lesson hint becomes exact;
    - after 6, James's guidance shows the remaining band(s) exact, a "talk-through".
  - The lesson grants timePearl Hint I as **vague** at session start.
  - Session state lives in the pure state tree, so save and Rewind stay valid outside the session.
- **New `RecipeKnowledge` system module** — the single owner of recipe acquisition:
  - Per-recipe known rungs: `base`, `hint1`, `hint2`, `master`. Each hint/technique rung is vague or exact.
  - It reuses the ported bench's hint representation, so a rung maps onto the bench's hidden ideal steps.
  - Rung → rank ceiling: base 2, hint1 3, hint2 4, master 5. Values are in data.
  - `seller_of(recipe)` is derived from ingredients: James if every ingredient ore is `time` or `life`, otherwise Wren. There is no per-recipe seller field.
  - `gate_met(recipe, rung)`:
    - James uses his contact relation, with thresholds per rung in data.
    - Wren uses the Guild faction perk tier: hint1 = Friendly, hint2 = Partner.
    - Base needs only that the seller is unlocked.
    - Master always returns false (not for sale).
  - `price(recipe, rung)` = the recipe's consumable sell price × the rung multiplier (base 10, hint1 15, hint2 20, in data), with per-recipe overrides.
    - Enhancement Powder's base override is about £300 (balance TBD).
    - Then the goodwill discount: up to 20%, scaling with James's contact relation or Wren's key-member standing. The curve is in data.
    - No market, Network gouge or faction-penalty modifiers.
  - `buy(recipe, rung)`:
    - refuses if the seller is locked, the gate isn't met, the rung is already exact, the rung is out of order (it needs the previous rung), or cash is short;
    - otherwise spends cash and writes the rung as exact. A vague rung is upgraded in place.
    - It emits state_changed and logs to the bank log, as other cash spends do.
  - `grant_rung(recipe, rung, specificity)` is used by events and quests. Exposed as the event op `grant_recipe_rung { recipe, rung, specificity }`, default exact.
  - Insight roll on each completed manual run (never on auto-craft):
    - chance = `insightBase + insightPerSkill × craftingSkill`, defaults 0.02 and 0.01, in data;
    - it only targets the lowest rung the player doesn't hold, master included;
    - success reveals one hidden ideal step of that rung as an **insight**: apparatus and position in the sequence, no target band. It is shown in the recipe book and the run result.
    - Matching the step in a later run turns it into a vague hint, using the prototype's existing experimenting rules. 3 in-band hits make it exact.
    - The roll uses the seeded RNG.
  - A per-recipe master source table in data: `{ recipe: { source: npc/faction id | null, pointer: text | null } }`. A null pointer renders as "???".
  - Seller unlock flags: James's shop unlocks at the end of `james_experiment`, Wren's at the end of `wren_introduction`.
- **Recipe data.** No procedure authoring happens in this spec. Every recipe's rung-tagged procedure comes from the port (P1, P2). `RecipeKnowledge` reads a rung's steps from those tags. A "rung owned" means all of that rung's hidden steps are at least vague; "rung exact" means all of them are exact.
- **Trade sheet recipe-seller mode.**
  - The existing contact-card "🤝 Trade" button on James's and Wren's cards opens the Trade sheet in a new mode: buy-only, a single Recipes category, rows grouped by recipe.
  - Each row shows: the rung, the new rank ceiling, the price after discount, and its state (owned / buyable / locked with reason / master "not for sale").
  - Confirming calls `RecipeKnowledge.buy` per row. There is no Bag item. The purchase appears on the lab recipe page immediately.
  - The Guild Marketplace faction shop is unchanged.
- **Recipe book.** Each recipe page shows its rung ladder: owned (vague/exact), insight-revealed steps, the source/lock reason of locked rungs, and the master pointer or "???".
- **Guild Benefits ladder.** Two read-only perk rows are added to the Guild's tiers: "Recipe hints I" at Friendly and "Recipe hints II" at Partner. They are rendered by the existing perks/Benefits UI and have no other effect.
- **Wren introduction.**
  - New event `wren_introduction`. It is triggered by a Wren pending message queued the day after `james_experiment` completes.
  - It sets flags, unlocks Wren's recipe trade and starts assay commissions.
  - A one-line variant applies if Wren is already an unlocked contact.
  - Ingram has one line.
  - Wren's placeholder `intro` text is replaced. PROSE-REVIEW.
- **Assay commissions.** These are a new offer kind in the existing offers pipeline. A commission is "deliver N × recipe at rank/tier ≥ R by day D"; it pays cash plus Guild faction relation.
  - R scales with the Guild perk tier: Stranger, Friendly, Partner, Sworn map to rank floors in data.
  - It uses existing offer expiry and pending caps.
  - Delivery takes items of tier ≥ R from inventory.
- **Dial / Movements (TBC final phase — direction only, not decided).** These are explored via ticket(s) once Dials are unlockable:
  - Movements become 4 bench recipes (attunement ore chosen at run start); rank = Movement tier; the chance roll is removed; player-only.
  - Recharge is granted with the gift. The other three are bench secrets, discovered only by experimenting.
  - A James quest where he searches his late master's notes and gives vague Movement insights.
  - A James Dial-repair quest: you deliver a time-attuned Capacitor Movement at rank 4+, and the reward is the timePearl master technique.

## Testing Decisions

- Good tests check external behaviour through the highest seam: state before, call, state after, plus emitted signals. No asserting private helpers or internal data shapes beyond the documented state paths.
- **Seam 1 — `RecipeKnowledge` (primary).** Headless tests against `GameState`, following the existing bench prototype tests as prior art. Cover:
  - seller derivation for all 17 recipes;
  - gates per seller and rung, including Wren's gates following the Guild tier;
  - price formula, override and discount bounds;
  - every `buy` refusal reason;
  - vague→exact upgrade on buy;
  - rung order enforced;
  - `grant_rung` and the event op;
  - rank ceiling per rung;
  - insight: seeded roll, next-rung-only targeting (master included), no roll on auto-craft, skill scaling, reveal without band, and the learn → vague → exact path.
- **Seam 2 — event runner (existing).** Play `james_experiment` and `wren_introduction` through the events system, following the existing event tests as prior art. Assert:
  - flags and ops (including `jamesExperimentSeen`; no `enhancementUnlocked` anywhere);
  - the lesson session can't be exited before rank 3;
  - the pool refills after a failure;
  - no time block is spent;
  - Rewind is refused during the session;
  - escalation at 3 and 6 fails;
  - output and XP are kept;
  - the event resumes on success;
  - the Wren message is queued the next day;
  - seller unlocks happen.
  - Jobs tests are updated for the "knows enhancementPowder" gate.
  - Content lint passes on the new events.
- **Seam 3 — offers pipeline (existing).** Assay commissions:
  - generation gated on `wren_introduction`;
  - rank floor by Guild tier;
  - delivery accepts tier ≥ R only;
  - payout of cash plus Guild relation;
  - expiry.
- **Screens.** One smoke test that the recipe-seller Trade mode builds and its confirm calls `buy`. The recipe book's rung display is covered by on-device QA. Screens never mutate state.

## Out of Scope

- The perform-to-master bench port itself, including authoring and rung-tagging every recipe's procedure (P1–P4 are prerequisites).
- Writing any master-technique quest. Only the framework, the op and the source table are in scope.
- The Guild story questline and Guild membership.
- Dial/Movement recipes, James's master's-notes quest and the Dial-repair quest. These are a TBC final phase with direction only.
- Save migration or compatibility.
- Recipe pages as Bag items, selling or gifting recipes, and stealing recipes.
- Final balance of prices, thresholds, insight odds and discount curve. Everything is in data and flagged for balance.
- Staff crafting changes beyond what the bench port defines.

## Further Notes

- New prose to flag PROSE-REVIEW:
  - all of `james_experiment` beyond the trimmed existing lines;
  - `wren_introduction`;
  - Wren's intro;
  - commission text;
  - insight lines;
  - locked-rung and master pointers;
  - Benefits rows.
- James's character must hold: grudging, dry, never warm. His Dial motive is hinted at, not explained.
- REFERENCE.md needs new sections when this lands: the recipe knowledge ladder, seller derivation, the price formula, insights, assay commissions and the new state paths. Update CODEMAP for the new system, data file(s) and the renamed event.
- Playtest questions:
  - Does rank 3 on the lesson feel earned rather than tedious?
  - Do the 3/6 escalation points feel right?
  - Is ×10/15/20 affordable at the point each gate opens?
  - Does the insight rate make pure discovery viable but rare?

# Lab revamp — perform-to-master crafting (prototype spec)

Status: ready-for-agent (prototype only)

## Problem

The Lab bench (`systems/bench.gd`, docs/M3-CALC-DISCOVERY.md) is a lottery over ~60 type-set × approach cells: tap ore, tap apparatus, roll. Refinement is the same roll repeated until tier 5. There are no decisions, no skill expression and no reason to return. It feels quick, once-and-done, and not fun.

## Direction (decided with the human, 2026-10-14)

Recipes stop being things you *find by lottery* and become things you *learn and master by performing*.

- **Recipe sources.** Mostly Guild of Applied Alchemists quests, plus some other quests and characters. The Guild questline is NOT designed yet — prototype first.
- **Simple start.** An acquired recipe starts as a simple base procedure, which is enough to reach a low rank.
- **Hints.** A hint improves the procedure: an extra step, a better amount or timing ("heat it a bit longer"). Hints raise the best quality you can reach.
  - Sources: characters, quests, Guild tests (tests unlock advanced recipes/hints; they are NOT gates between ranks), and the player's own experimenting.
  - How specific a hint is depends on the source: a cheap source is vague, a master is exact.
  - Experimenting yourself is always possible, but it's slow and partly trial and error.
- **Quality = knowledge × execution.** Hints say what to do; the player still has to do it well (e.g. keep a needle inside a band).
  - **Crafting skill widens the tolerance bands.**
  - Advanced recipes have tighter bands, so skill is what makes high-rank recipes doable.
- **Rank is per recipe (1–5).** A single manual run scoring at or above a rank threshold sets that rank; you only need to reach it once.
- **Perform once, then batch.** Auto-craft always runs at the best rank reached.
  - Doing a manual re-run is optional and occasionally pays a bonus: extra items, less calc spent, or more crafting XP than auto-craft. The XP bonus must not be so large that auto-crafting feels punishing.
- **Staff** craft at their own skill level. Only the player reaches max rank and makes special (hand-only) items.
- **Failure.**
  - You lose the calc spent so far.
  - A really bad run occasionally gives a flavour-text line.
  - Rewind always works.
- **Fixed content.** Recipes and procedures are authored, not randomized per save.
- **The four apparatus stay** (heat / grind / compress / distil), for now.
- **Catalysts: dropped** for now.

## The prototype

Two small, throwaway slices built side by side and launched from the **Debug app** (precedent: `systems/combat_prototype.gd`). They are fully sandboxed:

- Own state key `GameState.state["benchPrototype"]`, own data file `data/bench_prototype.json`, own screen.
- Own calc pool (seeded from data, with a debug refill button).
- Own recipe ranks.
- Own snapshot stack for Rewind.

The live bench, the real inventory, real XP and real recipe tiers are never touched. Nothing here changes REFERENCE.md mechanics. If a slice wins, a later spec ports it into the real bench.

Both slices share one core: recipe roster, score→rank, best rank, batch, re-run bonus, bad-run flavour, Rewind, and a skill override.

### Shared core rules (provisional numbers — all in data, tune freely)

- **Score.** Every manual run returns a score from 0 to 100.
- **Rank thresholds.**

  | Score | Rank |
  |---|---|
  | <40 | 1 |
  | 40–59 | 2 |
  | 60–74 | 3 |
  | 75–89 | 4 |
  | 90+ | 5 |

  Rank 5 is player-only (in the prototype this is just a label).
- **Best rank.** It only goes up. Batch ×N crafts at best rank: it costs the base calc and logs N items at that rank to a prototype ledger.
- **Re-run bonus.** A manual run whose rank is ≥ the current best rank rolls a bonus (30% chance).
  - The bonus is one of: +1 extra item, half the calc refunded, or crafting XP ×1.5 (auto-craft is ×1.0).
  - Debug picks which bonus type is active, so each can be felt.
  - XP is display-only.
- **Bad runs.** A score below 15 has a 1-in-3 chance of showing a flavour line from data. `PROSE-REVIEW:` drafts follow docs/CONTENT-GUIDE.md.
- **Calc cost.** Calc is spent as the run proceeds. Abandoning or failing loses what was spent.
- **Rewind.** The Rewind button restores `benchPrototype` to its state before the run.
- **Skill.** A debug crafting-skill slider (0–10) drives tolerance. Defaults to the player's real `craftingSkill`, which is read only.
- **Hints.** Debug toggles grant each authored hint at a chosen specificity (vague/exact). This stands in for quest/character sources, which are out of scope. Hints can also be earned by experimenting in-slice (see the slice sections below).

### Recipes in the prototype

`healingSalve` (life), `timePearl` (time), `healingBurst` (life+time). The ideal procedures below are provisional authored data:

| Recipe | Base procedure (known at start) | Hidden improvements (hints) | Base tolerance |
|---|---|---|---|
| healingSalve | grind life ×3 → heat to mid | heat slightly *higher*; finish with a distil (4 drips) | wide |
| timePearl | compress time to high → heat low | compress *longer* before heat; grind once between | medium |
| healingBurst | grind life → compress time → heat mid | distil between compress and heat; heat *lower* than you'd think | tight |

Base procedure alone, executed perfectly, caps out around rank 2–3. All hints plus good execution make rank 5 reachable.

## Slice A — Procedure (KCD-style)

A recipe is an ordered list of steps. Each step is one apparatus with a target value on a 0–100 gauge plus a tolerance band.

**Executing a step**
- **Heat:** hold; the needle rises; release inside the band.
- **Grind:** tap a counted number of strokes; each stroke has a timing window on a swinging pestle meter.
- **Compress:** hold to build pressure; release in the band; overshooting cracks the vessel and ends the run.
- **Distil:** drips fall on a beat; tap to collect each; a stray tap spoils it.

The screen animates and reports the raw released value or tap timings. The system scores them. No logic lives in the screen.

**Tolerance**
- Formula: `band_half_width = base_tol[recipe] × (1 + skillFactor × craftingSkill)`, with skillFactor provisionally 0.08.
- Step accuracy is 1.0 inside the band and falls linearly to 0 at 2× the band.

**Score**
- Each ideal step has a weight; score = Σ weight × accuracy.
- An ideal step that's missing from the player's procedure scores 0, so missing hints cap the score.
- Extra steps the ideal doesn't have take −5 each.

**Knowledge display**
- A known-exact step shows the true band.
- A vague step shows a wide fuzzy region that contains the band, plus a direction word ("a bit hotter"). The player has to find the sweet spot.
- An unknown step isn't shown at all.

**Experimenting**
- The player can insert any apparatus at any position, or nudge a target, before a run.
- After the run, the notebook shows a clue per step:
  - ✓ in band
  - ~ right step, wrong amount, plus a direction
  - ✗ no effect
  - "something changed": an inserted step matches a hidden ideal step at that position
- "Something changed" turns that step into a vague hint. Finding the sweet spot of a vague step on your own (3 runs scoring ✓ on it) upgrades it to exact.

**What the playtest asks**
- Is a second and third run still satisfying?
- Is the feedback enough to deduce from?
- Do the gauges feel good on a phone?

## Slice B — Resonance chart (Potion Craft-style)

> **Dropped (2026-10-15).** Procedure (Slice A) chosen; the chart slice's code, data and tests are deleted. Kept below for the record only.

A 2D chart. The marker starts at the origin. Each recipe is a circular region somewhere on the chart, with a bullseye at its centre; regions you haven't found are fogged.

**Moving the marker**
- **Pour:** hold a calc jar and the marker slides along that type's fixed direction for as long as you hold (life →, time ↑). Calc is spent per unit of distance. This is the execution.
- **Apparatus** are discrete transforms applied to the *next* pour:
  - heat rotates it 45°
  - grind halves its speed, for fine control
  - compress doubles it
  - distil pulls the marker 25% back toward the origin

**Finishing a run**
- **Bottle** ends the run. Score comes from the distance to the bullseye.
- The bullseye radius = `base_radius[recipe] × (1 + skillFactor × craftingSkill)`.
- Inside the bullseye scores 100, falling off linearly to the region edge (= rank 1), and 0 outside the region.

**Knowledge**
- Base recipe: the region is revealed, the bullseye isn't.
- Vague hint: a fuzzy cloud near the bullseye.
- Exact hint: the bullseye marked, or a revealed route segment.

**Experimenting**
- Fog clears along your path.
- Bottling anywhere inside an unfound region reveals that region.
- Landing inside the fuzzy cloud 3 times sharpens it to exact.

**What the playtest asks**
- Is navigating fun?
- Are there interesting alternative routes?
- Is the cost readable?
- Does the hold-to-pour control feel good on mobile?

## Playtest comparison

The human plays both slices and records:
- time per run
- whether they wanted another run without being asked
- whether discovery felt earned
- whether skill felt meaningful (try skill 0 vs 10)
- which re-run bonus felt best

Pick one slice, or a hybrid, for a production spec.

## Out of scope

- The Guild questline and other hint/recipe sources (stubbed by debug toggles).
- Catalysts.
- Staff crafting changes.
- Porting either slice into the live bench, save state, REFERENCE.md or CODEMAP data rows beyond the new prototype files.
- Any art beyond placeholder `_draw` gauges/chart.
- Animation polish.

## Open after prototype

- The exact rank → real item tier mapping when ported (today's tiers are 1–5 per cell).
- Which hand-only special items exist.
- The re-run bonus mix.
- The fate of today's discovery cells and census (M3-CALC-DISCOVERY.md §3.3).
- Whether bench secrets (recipes found only by experimenting) exist.

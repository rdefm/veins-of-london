# M3 — Calc Effect Discovery ("The Bench")

**Status: vision document.** Not a spec. Every number below is PROVISIONAL and marked as such; numbers are promoted to `docs/REFERENCE.md` only when this becomes a spec, and `REFERENCE.md` is canon the moment they land there. No code should be written against this file.

Supersedes the two-paragraph sketch in `VISION.md` §9a ("Discovery"). Where this file and `VISION.md` §9a disagree, this file is the newer intent — `VISION.md` gets patched when this is specced.

---

## 1. What this is

A bench mini-game where the player combines orichalchum types under a physical **approach** (heat it, compress it, grind it) to discover **calc effects** — consumables and passives they can then craft. Discovery is the primary channel; NPCs teaching effects is the secondary one.

The design problem, in the human's words: *"I want it to be fun and exciting to explore these, but I don't want someone to be frustrated that they don't know if there's a new calc effect to discover or not."*

Everything in §3 exists to solve that sentence.

### Pillar check (`VISION.md` §2)

| Pillar | How this feature serves it |
|---|---|
| 1. The business is the game | An experiment costs a time block. Every bench session is a day-routing decision against harvesting, selling and travel. Discovered effects become craftable goods with sale value. |
| 2. London is a place | Weak link, deliberately. The bench is at HQ. Approaches arrive via home rooms, which ties it to the property ladder rather than the map. |
| 3. Everything is priced | Ore, a block, and — the interesting one — **information**. The census (§3.3) is knowledge the player buys with their first probe. |
| 4. Menace and comedy | Failure prose is the main surface. Dry, administrative, occasionally alarming. One line per result, never three. |

---

## 2. The core model

### 2.1 A cell

The entire system is a grid of cells. A cell is:

```
cell = (type set) × (approach)
```

- **Type set** — one of the 5 single types, or one of the 10 unordered pairs. 15 sets.
- **Approach** — a physical technique (heat, grinding, compression, …). Roughly 5–6 in the launch roster.

**A cell holds at most one effect.** This invariant is what makes the whole UI honest and is not negotiable — it is what lets a cell be marked spent, and it is what gives refinement (§5) an unambiguous home.

15 sets × ~6 approaches = **~90 cells**, of which perhaps 15–30 hold anything at launch. There is deliberate headroom: new effects are added by filling empty cells, with no schema change and no rework.

### 2.2 Rejected: the ratio axis

An earlier pass had the player set a mix ratio (3:1, 2:2, 1:3) as a third axis. **Cut.** With honest cell feedback (§3) the ratio axis multiplies the grid by 3–5× without adding a decision the player can reason about, and it makes the phone-sized grid unreadable. Types and approach is enough.

---

## 3. The honesty contract

This is the heart of the feature. **The bench never lies to the player and never wastes their time twice.**

### 3.1 Cell states

Every cell is in exactly one of five states, and its state is always visible on the grid:

| State | Glyph | Meaning | Can you act on it? |
|---|---|---|---|
| **Untried** | `·` | Never probed. | Yes — this is the game. |
| **Inert** | `✗` | Probed; there is genuinely nothing here. Permanent. | No. Warned and blocked. |
| **Hot** | `○` | Probed; **there is something here** and you failed to bring it out. | Yes — retry, with pity (§3.4). |
| **Found** | `✦` | Effect discovered and craftable. | Yes — refine (§5). |
| **Unavailable** | `—` | You have not learned this approach. | No — but it counts in the census (§3.3). |

The crucial pair is Inert vs Hot. A probe **always resolves the truth of the cell**:

- **Empty cell** → no roll happens. Result is `Inert`, permanently. The ore and block are still spent — you paid for the information, which is the point.
- **Occupied cell, roll succeeds** → `Found`.
- **Occupied cell, roll fails** → `Hot`, and the result text says plainly that something is there. The player is never left guessing whether to come back.

Crafting skill affects **only the odds on an occupied cell**. It can never cause a false Inert.

### 3.2 No hard skill gates

**No effect is locked behind a crafting-skill requirement.** A skill-1 player probing the cell that holds Failsafe gets a near-miss and a Hot marker, not a wall. Low skill means long odds and a longer pity climb, never a closed door.

This was an explicit call: skill paces discovery through probability, not through permission.

### 3.3 The census — the anti-frustration guarantee

The first probe of any type set (whatever its outcome) **surveys the set** and permanently reveals how many effects it contains — counting effects sitting behind approaches the player has not learned yet.

```
⧖+✦  TIME · LIFE        3 present · 1 known
```

This is the answer to "is there anything left to find here?" It is answered, forever, for the price of a single experiment. It also does the drip-feed work: seeing `3 present · 1 known` with only two approaches learned tells the player something waits behind a technique they don't have — a wanting, not a frustration.

A set with nothing in it surveys to `barren` and the player never touches it again.

### 3.4 Pity

Each Hot cell carries a private miss counter. Every failed probe on that cell adds a permanent bonus to its next roll. A cell the player keeps returning to will yield. The counter is never shown; the honest `Hot` marker is the visible promise, and the pity counter is what makes the promise true.

Pity is per-cell and does not decay.

---

## 4. Approaches

Approaches are the content valve. Learning one re-opens every set the player thought they'd emptied, which is why they are the drip rather than the effects themselves.

**PROVISIONAL roster — PROSE-REVIEW required on all names and flavour:**

| Approach | Source | Notes |
|---|---|---|
| Heat | Known from the start | The obvious one. Everyone starts here. |
| Grinding | Known from the start | Cheap, crude, surprisingly productive. |
| Compression | `workshop` room (tier: flat) | First real gate; ties the bench to the property ladder. |
| Calcining | Taught — James | Story-paced. James is insufferable about it. |
| Distilling | `lab` room (tier: compound) | Late. Opens a swathe of previously-inert-looking sets. |
| Quenching | Taught — faction storyline reward | One of the 3-event storyline rewards in `VISION.md` §14. |

Sources are the two channels chosen for approaches: **home rooms/devices** and **taught by contacts**. A device that enables an approach is explicitly allowed by the schema (`source: {type:"device", id:"..."}`) but none ships in the launch roster.

When a new approach is learned, the bench pushes a notification and every surveyed set whose census still shows unknowns should visibly refresh. This moment is the feature's second-best beat after a discovery and deserves the juice budget.

---

## 5. Refinement

A `Found` cell is not finished. Re-experimenting it refines the effect it holds.

- Refinement tiers are **uncapped**. Tier 1, 2, 3, … forever.
- **Ore cost rises** with each tier.
- **Success probability falls** with each tier, asymptotically toward a floor.

So refinement is a self-limiting money sink: a rich, high-skill player can push a favourite effect a long way, but the curve turns bad and there is always a better use of the block. No cap needed because the maths is the cap.

What a tier *does* is defined per-effect in data (`refineStep`), not globally — a healing effect gains percentage points, a freeze effect gains turns, a passive gains duration. This keeps refinement expressive without a universal potency formula.

Refinement is only available on `Found` cells. It is **not** a fallback for Inert cells — an Inert cell is dead and stays blocked.

---

## 6. The loop

```
HQ → Bench
  ↓
Pick 1 or 2 calc types            (the 5 glyphs; tap one, or tap two to pair)
  ↓
Set panel: census line + approach grid
  ↓
Pick an approach                  (Inert rows blocked with a reason; Unavailable rows greyed)
  ↓
Confirm: ore cost · 1 time block · odds shown
  ↓
[animation]
  ↓
Result card:  ✦ FOUND  |  ○ something is here  |  ✗ inert  |  ✦ refined to II
  ↓
Note appended to the set's bench notebook
```

Roughly three experiments a day if the player does nothing else — the bench competes with the rest of the day, which is pillar 1 working as intended.

---

## 7. Provisional numbers

**All PROVISIONAL. Tuning targets, not canon.** Promote to `REFERENCE.md` at spec time.

| Quantity | Proposal | Rationale |
|---|---|---|
| Time cost | 1 block per experiment | Chosen: the bench must compete with the day. |
| Ore cost — discovery | 3 units of each type in the set (3 single / 3+3 pair) | Chosen: cheap. Experimenting is a time sink, not a money sink, so ore-poor early players can play. |
| Ore cost — refinement tier *n* | `3 × (n + 1)` of each type | Rises fast enough to bite by tier 3. |
| Discovery chance | `min(0.90, 0.35 + (skill − 1) × 0.12 + workshopBonus + pity)` | Mirrors the shape of `craftChance` (R§3.5) so it reads as the same game. |
| Pity | `+0.12` per prior miss on that cell, no cap | Guarantees convergence within a handful of returns even at skill 1. |
| Refinement chance, tier *n* | `max(0.08, 0.55 + (skill − 1) × 0.10 − 0.15 × (n − 1))` | Floors at 8% — always possible, rarely worth it. |
| XP — discovery success | 40 | Above a craft (20–35): discovery is the harder act. |
| XP — Hot (near miss) | 12 | Failure still teaches. |
| XP — Inert | 6 | You learned something, just not much. |
| XP — refinement success | 30 | |
| Ore deduction | Always, regardless of outcome | Matches `attempt_craft` and `seed`. Consistency over kindness. |

---

## 8. UI

Lives in **HQ**, as a third card alongside the workbench and gym (`scenes/screens/hq.gd`). Candidate in-fiction name: **the Bench**. Recipes stay under the workbench; the bench is where recipes come *from*.

### 8.1 Type selection — a deviation from `VISION.md` §9a

`VISION.md` §9a specifies "a horizontal row of the 5 type icons; between each pair of adjacent icons sits a link icon." **That only reaches 4 of the 10 pairs.** Recommended replacement: **tap-to-select, up to two.** Tap `⧖` to work a single type; tap `⧖` then `✦` to work the pair. Tap again to deselect. This reaches all 10 pairs, works one-handed, needs no drag gesture, and is a smaller control than a link row.

`VISION.md` §9a should be patched to match when this is specced.

### 8.2 The set panel

```
⧖+✦  TIME · LIFE                    3 present · 1 known

  heat          ✦  Healing Burst          refine → II
  grinding      ✗  inert
  compression   ○  something nearly took
  calcining     ·  untried
  distilling    —  distilling not learned
  quenching     —  quenching not learned

                                        [ bench notes ]
```

Rules:
- State glyph and a plain-English state on every row. No hover-only information — this is a phone.
- Inert rows are **not tappable**. Tapping shows the reason, does not open a confirm.
- The census line is the first thing under the header, because it is the answer to the player's main question.
- Unavailable rows are shown, not hidden. Knowing what you're missing is the drip.

### 8.3 The confirm card

Cost, block warning, current odds as a percentage, and for a refinement the current and next tier. Odds are shown honestly, including the pity bonus baked in — the player should be able to watch the number climb on a Hot cell across returns. That climbing number is the pity mechanic made visible without ever exposing a counter.

### 8.4 Bench notes

A per-set scrollable log, appended one line per experiment, persisted in state:

```
TIME · LIFE — bench notes

 d4   heat         inert. nothing in it at all.
 d6   compression  something nearly took, then didn't.
 d7   compression  something nearly took, then didn't.
 d9   heat         ✦ HEALING BURST
```

Cheap to build, extremely on-tone for a text-forward game, and it makes a run of failures read as fieldwork rather than as bad luck. Bounded (last ~20 per set) to keep the state tree small.

### 8.5 The animation

One shared bench animation, outcome-agnostic until it resolves, so the player cannot read the result early. Target 1.2–1.8s, skippable on tap. Discovery gets a distinct reveal; Inert should land flat and a little sad.

---

## 9. Data schema (sketch)

### 9.1 `data/approaches.json`

```json
{
  "heat":        { "name": "Heat",        "symbol": "△", "source": {"type":"start"} },
  "grinding":    { "name": "Grinding",    "symbol": "◇", "source": {"type":"start"} },
  "compression": { "name": "Compression", "symbol": "▽", "source": {"type":"room","id":"workshop"} },
  "calcining":   { "name": "Calcining",   "symbol": "◈", "source": {"type":"contact","id":"james"} },
  "distilling":  { "name": "Distilling",  "symbol": "○", "source": {"type":"room","id":"lab"} },
  "quenching":   { "name": "Quenching",   "symbol": "◉", "source": {"type":"faction","id":"guild"} }
}
```

### 9.2 Effects fold into `data/recipes.json` — they do not get a parallel file

A discovered effect *is* a recipe. Building a second system next to `recipes.json` would mean two crafting paths, two XP flows and two inventory conventions. Instead, extend the recipe schema:

```json
"healingBurst": {
  "name": "Healing Burst",
  "symbol": "✚",
  "ingredients": { "time": 4, "life": 4 },
  "discovery": { "types": ["life","time"], "approach": "heat" },
  "baseSuccess": 0.30,
  "effectPower": [0, 8, 10, 12, 15, 18],
  "refineStep": { "field": "effectPower", "add": 3 },
  "xpReward": 30,
  "eventUsable": true,
  "description": "..."
}
```

**Two migrations this forces, both needing human sign-off before spec:**

1. `ingredient: "time"` (singular string) → `ingredients: {"time": 5}` (dict). Touches `systems/crafting.gd`, `systems/devices.gd`, `systems/rooms.gd` (lab), `scenes/screens/hq.gd`, and `REFERENCE.md` §1.3. Mechanically neutral for existing recipes.
2. `baseCalcCost` is superseded by `ingredients` and the skill-scaling in `calc_cost()` needs re-expressing per-ingredient.

Existing `timePearl` / `enhancementPowder` / `rewind` get `discovery: null` and `taughtBy` set — they are tutorial-taught and never appear on the bench grid. **Their cells must therefore be authored as genuinely empty**, or the census will over-count.

### 9.3 Type set key

Canonical form: types sorted alphabetically, joined with `+`. `"life"`, `"life+time"`. Never `"time+life"`. This must be a single shared helper — an inconsistent key is the most likely bug in the whole feature.

---

## 10. State schema (sketch)

Pure data only, per the constitution. Added under `player`:

```
player.bench: {
  approaches: ["heat", "grinding"],       # learned approach ids
  surveyed:   { "life+time": 3 },         # setKey -> effect count, written on first probe
  cells: {
    "life+time|heat":        { "state": "found", "misses": 2, "refine": 1 },
    "life+time|compression": { "state": "hot",   "misses": 3, "refine": 0 },
    "life+time|grinding":    { "state": "inert", "misses": 0, "refine": 0 },
  },
  notes: { "life+time": [ { "day": 9, "approach": "heat", "outcome": "found" } ] },
}
```

Notes:
- Cells are written lazily — absent key means `untried`. Keeps the save small and the default trivial.
- `notes` arrays bounded at ~20 per set; oldest dropped.
- Note entries store an `outcome` enum, not prose. **Prose is generated at render time from data** so it can be rewritten without a save migration. This matters.
- Everything here survives snapshot/Rewind unchanged because it is plain data. Worth an explicit test: Rewind must not un-discover an effect.

---

## 11. Effect catalogue

**The human is supplying the initial effect list.** Until then, the placeholder is `VISION.md` §10, which already names combination effects (Healing Burst = time + life; Failsafe = time + life) and single-type ones (Blast, Shield, Prophet's Breath, Pan's Prank, Luck Be a Lady, Black Hole, Healing Salve).

Note the §10 collision: Healing Burst and Failsafe are both listed as time + life, but a cell holds one effect, so they must sit on different **approaches** within that set. That's the schema working as intended, and it is a good illustration — one pair, two approaches, two very different effects.

Authoring rules for whoever fills the grid:
- Every set needs a deliberate effect count, including zero. A barren set is a design decision recorded in data, not an accident of omission.
- Spread effects across approaches so early-approach players find *something* in most sets, and late approaches feel like they unlock a layer rather than a scattering.
- Prefer a set's effects to share a theme. `time+life` reading as "the medical pair" is worth more than mechanical spread.

---

## 12. Discovery channels in scope

| Channel | In scope | Notes |
|---|---|---|
| **Experimentation** | Yes | This document. |
| **Taught by NPCs** | Yes | James scenes and faction storylines grant effects outright, and grant approaches. A taught effect marks its cell `Found` directly and decrements nothing from the census. |
| **Bought fragments** | **No** | Deferred with the Soho marketplace (M4). When it lands, the recommendation is that fragments reveal a *cell location* ("someone's notes say: life and time, under heat") rather than the effect — folding purchase into the mini-game instead of bypassing it. |

---

## 13. Interactions with existing systems

- **`craftingSkill`** — the bench both consumes it (odds) and feeds it (XP). Discovery XP is the largest single source, which is intended: experimenting is how a crafter grows.
- **`workshopBonus`** (`Home.get_workshop_bonus()`) — applies to discovery odds exactly as it does to `craftChance`. Rooms already carry a crafting bonus; they should not need a second one.
- **Affinities** (`VISION.md` §5b, unbuilt) — when they land, an Attuned type should raise odds on any cell whose set contains it. Noted, not designed here.
- **Time blocks** — one per experiment via `TimeSystem`. No special casing.
- **Snapshots / Rewind** — `player.bench` is pure data and rides along free. Needs a test.
- **Lab room** (R§3.10) — a contact in the lab crafts to thresholds. It should **not** experiment; discovery is the player's. Assigning a contact to the lab enabling the `distilling` approach is the lab's contribution here.

---

## 14. Explicitly out of scope

- The ratio axis (§2.2).
- Triple-type sets. The schema tolerates them (`types` is an array); the launch roster and the UI do not.
- Minor Incidents on failure. Considered and dropped — with honest feedback the tension already sits in the Hot/Inert reveal, and injury on top of a spent block is punitive.
- Bought recipe fragments (M4).
- Affinities.
- Any change to how crafting itself resolves, beyond the `ingredients` migration in §9.2.

---

## 15. Open questions for the human

1. **The effect list.** Blocking for the spec, not for this document.
2. **In-fiction name.** "The Bench" is a placeholder. It wants a name Archie would use.
3. **Approach names and count.** The §4 roster is invented. Six may be one too many for the phone grid; five is probably right.
4. **Does a *taught* effect count against the census before it's taught?** If James is going to hand over Failsafe at relation 80, does `time+life` show `3 present` from day one, including an effect the bench can never find? Recommendation: **yes, count it** — the census promise is "how many exist", and a player who probes every approach and comes up one short has learned something true about the world. But it risks reading as a bug.
5. **Should Inert cells ever revive?** Currently permanent. A late-game device that "re-reads" a spent cell is a tempting content lever, and also a straight betrayal of §3's contract. Recommendation: never.

---

## 16. Ticket shape (sketch, for when this becomes a spec)

Dependency-sorted, roughly one commit each:

1. `data/approaches.json` + approach unlock resolution (rooms, contacts, start).
2. Recipe schema migration: `ingredient` → `ingredients`, `calc_cost` per-ingredient. Existing behaviour unchanged, tests green.
3. `player.bench` state shape, defaults, save round-trip, snapshot test.
4. `systems/bench.gd` — set keys, cell state resolution, census, probe roll, pity.
5. Refinement: tiers, cost and odds curves, `refineStep` application.
6. Bench card in HQ: type selection, set panel, approach grid.
7. Confirm card + result card + animation.
8. Bench notes: state, rendering, prose table.
9. Effect content pass (blocked on §15.1).
10. Taught-effect grants wired into events and faction rewards.
11. Balance pass against the §7 provisional numbers.

---

**PROSE-REVIEW:** all approach names and flavour in §4, all result and cell-state strings in §8, and the notebook lines in §8.4 are new prose drafted against `docs/CONTENT-GUIDE.md` and need a human audit before they ship.

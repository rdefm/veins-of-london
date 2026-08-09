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

The entire system is a grid of cells — **as a data model only; the player never sees a grid** (§8.0). A cell is:

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

Every cell is in exactly one of five states, and its state is always stated plainly on the pairing panel (§8.3) whenever the player is looking at that pairing:

The left column is the internal enum. The right-hand column is roughly how the pairing panel says it — **in words, never as a glyph legend** (§8.3).

| State | Meaning | Can you act on it? | Reads as |
|---|---|---|---|
| **Untried** | Never probed. | Yes — this is the game. | *(nothing at all — a bare approach name)* |
| **Inert** | Probed; there is genuinely nothing here. Permanent. | No. Dimmed and untappable. | "nothing in it, and never was" |
| **Hot** | Probed; **there is something here** and you failed to bring it out. | Yes — retry, with pity (§3.4). | "something nearly took" |
| **Found** | Effect discovered and craftable. | Yes — refine (§5). | "✚ Healing Burst · refine to II" |
| **Unavailable** | You have not learned this approach. | No — but it counts in the census (§3.3). | "needs a Lab" |

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

This is the answer to "is there anything left to find here?" It is answered, forever, for the price of a single experiment. It also does the drip-feed work: knowing a pairing holds three things when you've only ever pulled one out tells the player something waits behind a technique they don't have — a wanting, not a frustration.

**Voice.** In play the census speaks prose, not statistics:

> *You've had one thing out of this pairing. There is more in it — something you haven't the technique for yet.*

The exact numbers are available on the bench notes screen (§8.5) for anyone who wants to plan. Mystery by default, precision on demand. The guarantee is identical either way; only the register changes. A set with nothing in it surveys to barren and says so flatly.

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
HQ → Bench                        found effects · run an experiment · notes
  ↓
Pick 1 or 2 calc types            list of 5 type rows, tap to select
  ↓
Pairing panel                     prose census + your approaches, state marked
  ↓
Pick an approach                  spent rows untappable; unlearned rows show their source
  ↓
Confirm: ore cost · 1 time block · odds shown
  ↓
[animation]
  ↓
Result:  found · something nearly took · inert · refined to II
  ↓
Note appended to that pairing's bench notes
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

### 8.0 The governing rule: no grid, and no menu of things you haven't done

**The 15 type sets are never enumerated anywhere in the UI.** Not as a matrix, not as a list, not as a collection tracker. The player assembles a pairing from a type picker each time they sit down, and that pairing's state only exists on screen while they're inside it.

This costs a little wayfinding and buys the thing the feature is for: the player is *poking at something*, not completing a table. Every screen below is a vertical stack of `UI.card()` rows in a `ScrollContainer` — identical construction to HQ, Map and Phone. Nothing here needs a new widget.

The one place the space is laid out in full is the bench notes screen (§8.5), which the player opts into and which is framed as *their own record* rather than the game's checklist.

### 8.1 Bench home

Reached from HQ. Lists what you have, never what you lack.

```
┌──────────────────────────────────┐
│ The Bench                        │
│ Two burners, a vice, and a lot   │
│ of ruined saucers.               │
│                                  │
│ Approaches: heat, grinding       │
├──────────────────────────────────┤
│ FOUND                            │
│  ✚ Healing Burst           II    │
│    time · life, under heat       │
│  ↯ Blast                         │
│    physics, under compression    │
├──────────────────────────────────┤
│      [ Run an experiment ]       │
│      [ Bench notes ]             │
└──────────────────────────────────┘
```

- The found list is the player's trophy shelf and their route back to refining — tapping an effect goes straight to its pairing panel.
- Approaches known are listed here, and only here, as a plain sentence. Their unlock sources live on the pairing panel where they're actionable.
- With nothing found yet the card carries a single line of encouragement and the button. No empty-state list of 15 pairings.

### 8.2 Type picker — a deviation from `VISION.md` §9a

`VISION.md` §9a specifies "a horizontal row of the 5 type icons; between each pair of adjacent icons sits a link icon." **That only reaches 4 of the 10 pairs**, and an icon row with interstitial link targets is a fiddly hit-test on a phone. Replaced with a **list of 5 rows, tap to select, maximum two**:

```
┌──────────────────────────────────┐
│ What are you working with?       │
│ Pick one, or two to combine.     │
├──────────────────────────────────┤
│  ⧖  Time                    24   │
│  ↯  Physics                  8   │
│  ✦  Life          selected  31   │
│  ⚄  Fate                     0   │
│  ❋  Emotion                 12   │
├──────────────────────────────────┤
│  ⧖ · ✦   time and life           │
│           [ Continue ]           │
└──────────────────────────────────┘
```

- Right column is ore held, because an experiment costs ore and a player with 0 Fate should see that before they commit to a route.
- Selection is a toggle; tapping a third type replaces the older selection rather than erroring.
- Rows carry **no census, no progress, no state**. This screen must stay a plain list of materials — the moment it grows status columns it becomes the enumeration this design is avoiding.
- `VISION.md` §9a gets patched to match when this is specced.

### 8.3 Pairing panel — the one place state is fully visible

Having assembled a pairing, the player sees everything known about *that pairing only*. Approach rows carry their state inline: no hunting, no wasted taps, no hover-only information.

```
┌──────────────────────────────────┐
│ ⧖ · ✦   Time and Life            │
│                                  │
│ You've had one thing out of this │
│ pairing. There is more in it —   │
│ something you haven't the        │
│ technique for yet.               │
├──────────────────────────────────┤
│  Heat                            │
│    ✚ Healing Burst · refine to II│
│                                  │
│  Grinding                        │
│    nothing in it, and never was  │
│                                  │
│  Compression                     │
│    something nearly took         │
│                                  │
│  Calcining                       │
│                                  │
│  Distilling                      │
│    needs a Lab                   │
├──────────────────────────────────┤
│      [ Notes on this pairing ]   │
└──────────────────────────────────┘
```

Rules:
- Every state is written in words. No glyph legend to learn, no colour-only encoding (accessibility, `VISION.md` M7).
- **Spent rows are dimmed and untappable.** This is the warning made structural — the player cannot repeat a dead experiment even if they want to.
- **Untried rows are blank below the name.** Absence of a subtitle is the cleanest possible "nothing known yet", and it keeps the panel from reading as a filled-in form.
- **Unlearned approaches show their source** ("needs a Lab", "James might know"), which turns a locked row into a goal and quietly sells home rooms. This is the drip doing its job.
- The prose census sits directly under the header, because it is the answer to the player's main question.
- Scoping the full state view to a single pairing is the compromise that makes this work: six rows of honest status is a workbench, ninety is a spreadsheet.

### 8.4 Confirm and result

Confirm card: ore cost (`UI.format_cost_label`), the block cost (`UI.format_block_cost_label`), and current odds as a percentage. For a refinement, current and next tier.

Odds are shown **with the pity bonus already baked in**, so a player returning to a near-miss watches the number climb across visits. That climbing number is the pity mechanic made visible without ever exposing a counter — and it is the strongest possible argument to come back.

One shared animation, outcome-agnostic until it resolves so the result can't be read early. Target 1.2–1.8s, skippable on tap. Discovery gets a distinct reveal; inert should land flat and a little sad.

Result card, one line of prose per outcome:

| Outcome | Register |
|---|---|
| Found | The beat the whole feature exists for. Name, symbol, what it does, and that it's craftable now. |
| Refined | Quieter. Old value → new value, plainly. |
| Nearly took | A lure, not a consolation. Says outright that something is there. |
| Inert | Flat. Not funny, not cruel. It just isn't in there. |

### 8.5 Bench notes — the only full-space view, and it's the player's

An opt-in screen, framed as the player's own journal rather than the game's completion tracker. This is where numbers are allowed.

```
┌──────────────────────────────────┐
│ Bench notes                      │
├──────────────────────────────────┤
│ TIME · LIFE          3 · 1 found │
│  d4  heat        nothing in it   │
│  d6  compression nearly took     │
│  d7  compression nearly took     │
│  d9  heat        ✚ HEALING BURST │
├──────────────────────────────────┤
│ PHYSICS              2 · 1 found │
│  d11 compression ↯ BLAST         │
└──────────────────────────────────┘
```

- **Only pairings the player has actually touched appear.** The unexplored 15 are still never listed. The notes grow as a record of where you've been, not a menu of where you haven't.
- Numeric census here (`3 · 1 found`) per the "precision on demand" call.
- Entries are bounded at ~20 per pairing, oldest dropped.
- Prose is generated at render time from stored enums (§10), never stored as strings.

Cheap to build, exactly on-tone for a text-forward game, and it makes a run of failures read as fieldwork rather than as bad luck.

### 8.6 Navigation state

Follows the existing `mapNav` / `phoneNav` convention — pure data, no node references:

```
state.benchNav: { view: "home", types: [], approach: null }
```

`view` ∈ `home | picker | pairing | notes`. Back behaviour mirrors the Map tab's drill-down.

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

Existing `timePearl` / `enhancementPowder` / `rewind` get `discovery: null` and `taughtBy` set — they are tutorial-taught and never appear as bench discoveries. **Their cells must therefore be authored as genuinely empty**, or the census will over-count.

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

Plus navigation at the top level of `state`, alongside `mapNav` and `phoneNav` (§8.6):

```
state.benchNav: { view: "home", types: [], approach: null }
```

Notes:
- Cells are written lazily — absent key means `untried`. Keeps the save small and the default trivial.
- `benchNav` is transient view state and resets on load, exactly like `mapNav`.
- `notes` arrays bounded at ~20 per set; oldest dropped.
- Note entries store an `outcome` enum, not prose. **Prose is generated at render time from data** so it can be rewritten without a save migration. This matters.
- Everything here survives snapshot/Rewind unchanged because it is plain data. Worth an explicit test: Rewind must not un-discover an effect.

---

## 11. Effect catalogue

**The human is supplying the initial effect list.** Until then, the placeholder is `VISION.md` §10, which already names combination effects (Healing Burst = time + life; Failsafe = time + life) and single-type ones (Blast, Shield, Prophet's Breath, Pan's Prank, Luck Be a Lady, Black Hole, Healing Salve).

Note the §10 collision: Healing Burst and Failsafe are both listed as time + life, but a cell holds one effect, so they must sit on different **approaches** within that set. That's the schema working as intended, and it is a good illustration — one pair, two approaches, two very different effects.

Authoring rules for whoever fills the cells:
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
- **Any screen that enumerates the 15 type sets** (§8.0). Not as a grid, not as a list, not as a completion tracker. This is a standing constraint on the feature, not a phase-one cut.
- Triple-type sets. The schema tolerates them (`types` is an array); the launch roster and the UI do not.
- Minor Incidents on failure. Considered and dropped — with honest feedback the tension already sits in the Hot/Inert reveal, and injury on top of a spent block is punitive.
- Bought recipe fragments (M4).
- Affinities.
- Any change to how crafting itself resolves, beyond the `ingredients` migration in §9.2.

---

## 15. Open questions for the human

1. **The effect list.** Blocking for the spec, not for this document.
2. **In-fiction name.** "The Bench" is a placeholder. It wants a name Archie would use.
3. **Approach names and count.** The §4 roster is invented. Six rows may be one too many on the pairing panel; five is probably right.
4. **Does a *taught* effect count against the census before it's taught?** If James is going to hand over Failsafe at relation 80, does `time+life` show `3 present` from day one, including an effect the bench can never find? Recommendation: **yes, count it** — the census promise is "how many exist", and a player who probes every approach and comes up one short has learned something true about the world. But it risks reading as a bug.
5. **Should Inert cells ever revive?** Currently permanent. A late-game device that "re-reads" a spent cell is a tempting content lever, and also a straight betrayal of §3's contract. Recommendation: never.
6. **Wayfinding cost of never listing the pairings.** With no index, a player who wants to find everything must remember which of 15 pairings they've worked. Bench notes (§8.5) is the mitigation, but it only lists pairings already touched — there is deliberately no way to see *untouched* ones. Watch this in playtest: if players report feeling lost rather than curious, the cheapest fix is a line on bench notes ("you've worked 6 pairings") without ever naming the other nine.
7. **Does the found list on bench home include taught effects?** Recommendation: yes, with their origin line reading "from James" instead of a pairing and approach. One shelf for everything you know how to make.

---

## 16. Ticket shape (sketch, for when this becomes a spec)

Dependency-sorted, roughly one commit each:

1. `data/approaches.json` + approach unlock resolution (rooms, contacts, start).
2. Recipe schema migration: `ingredient` → `ingredients`, `calc_cost` per-ingredient. Existing behaviour unchanged, tests green.
3. `player.bench` state shape, defaults, save round-trip, snapshot test.
4. `systems/bench.gd` — set keys, cell state resolution, census, probe roll, pity.
5. Refinement: tiers, cost and odds curves, `refineStep` application.
6. `state.benchNav` + bench home card in HQ (found list, entry buttons).
7. Type picker screen and pairing panel with inline approach states.
8. Confirm card + result card + animation.
9. Bench notes screen: state, rendering, prose table.
9. Effect content pass (blocked on §15.1).
10. Taught-effect grants wired into events and faction rewards.
11. Balance pass against the §7 provisional numbers.

---

**PROSE-REVIEW:** all approach names and flavour in §4, all result and cell-state strings in §8, and the notebook lines in §8.4 are new prose drafted against `docs/CONTENT-GUIDE.md` and need a human audit before they ship.

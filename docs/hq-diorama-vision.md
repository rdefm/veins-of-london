# HQ Diorama — Vision & Spec

**Status:** Vision + buildable spec for the HQ tab redesign. Agreed with the
human in a grilling session, 2026-09-06. Where this document and
`docs/ART-BIBLE.md` disagree on pixel technique, ART-BIBLE wins; where it
and `docs/M3-CALC-DISCOVERY.md` disagree on discovery *rules*, M3 wins —
this doc only re-shapes M3's front-end, never its mechanics.

**Prose:** contains no final player-facing copy. Strings drafted during
implementation are `PROSE-REVIEW:` material per `CLAUDE.md`.

---

## 1. Direction

The HQ tab stops being a scrolling stack of cards and becomes **a room you
look at**. One pixel-art plate per property tier fills the tab; every HQ
function is reached by tapping an object drawn in that room. There is no
card list underneath it and no second way to do anything.

Three consequences we are choosing deliberately:

1. **The room is a readout.** A glance tells you what you own, what's
   installed, and what's missing — the empty lock plate on the door is the
   security screen's "not installed" row, drawn.
2. **Preparation becomes a place.** The Dial loadout moves *out* of the
   global bag drawer and into a view you can only reach from the room. You
   prep at HQ or you fight with what you brought.
3. **Anything not drawn is unreachable.** This is the discipline the design
   costs. Every function below has an object, or it has been moved off the
   tab entirely (see §7, the property app).

Mood, palette, lighting and pixel technique are ART-BIBLE §1–§4 unchanged:
overcast daylight, muted, top-left key light, genuine pixel grid, no
anti-aliasing surviving into the shipped asset.

## 2. Scope

**In:** the HQ tab; the Lab (as a diegetic bench replacing the current
picker/pairing/confirm flow); the security door; the Dial loadout; the
rooms floorplan; a new property app on the Phone tab.

**Out (explicit non-goals):**
- Other tabs' chrome. Phone and Map are untouched.
- Game mechanics. No formula, cost, probability, or data table changes.
  Every system under `systems/` keeps its current behaviour; this is a
  front-end replacement, top to bottom.
- A navigable multi-room dollhouse. Rooms other than the hero room exist on
  the floorplan, not as places you walk to (§6).
- Tiers 2–6 art in v1 (§10).

## 3. The room

**One hero room per tier. Single view — no panning, no scrolling.** The
door, desk, bed, noticeboard and ore store are all in frame at once, which
is what makes the room glanceable. The room sits inside the app's normal
chrome (top bar + nav dock), giving a canvas of **390 × 660 logical px**,
authored at **195 × 330** and displayed at **2× nearest** so the pixel grid
stays honest.

Higher tiers are *the same room, posher and denser* — never a different
layout discipline. The lab bench gains apparatus as rooms are built (§5),
the ore store upgrades bag → strongbox → safe, the door accumulates
hardware.

### 3.1 Zones

| Zone | Object | Opens | First tier present |
|---|---|---|---|
| Dial | bag & umbrella on the desk | Dial loadout view (§4) — **diegetic** | bedsit |
| Lab | lab equipment on the desk | Lab bench (§5) — **diegetic** | bedsit |
| Security | front door | Security view (§8) — **diegetic**; *hostile-door state* when a raid is pending, opening Defend instead | bedsit |
| Rest | the bed | Rest directly, no intermediate view | bedsit |
| Rooms | pinned noticeboard | Floorplan (§6) — **diegetic** | bedsit (empty plan; teaches the object) |
| Ore store | bag → strongbox → safe | readout: stored ore + "this is what a raid takes" | bedsit |
| Gym | pull-up bar & kettlebells | Train — **list-style panel** with a training animation | flat (room-gated) |
| Veins | wall map / pinboard | navigates to the existing vein list screen | safehouse (veinStation room) |

**Removed from the tab entirely:** tier upgrade and property stats → the
property app (§7). Contact room assignment → the floorplan (§6).

### 3.2 Affordance

Tappable objects carry a **coloured pixel outline baked into the generated
art**. Hit regions are determined afterwards against the finished plate.

Rules:
- A hit region is **≥ 44 × 44 logical px**, regardless of how small the
  outlined object is.
- Hit regions **do not overlap**. Two objects that genuinely overlap in the
  art share one region and open a chooser (the `map_bubble.gd` pattern).
- A hit region for an object not present at this tier does not exist — no
  invisible taps, no disabled ghosts.

State-varying outlines (bright = wants attention, dim = idle) are
**deferred**, see §12.

### 3.3 Sub-view style

Diegetic where the object *is* the information — the door with its slots,
the Dial with its sockets, the floorplan, the bench. List-style panels
where the content is a list and drawing it as furniture would only make it
harder to read (Train, vein list).

Sub-views are **full-bleed**: top bar and nav dock auto-hide while you are
inside one, and return at the room level. Time blocks matter when deciding
what to do; they don't matter once you're at the bench.

## 4. The Dial view

Reached only from the bag-and-umbrella zone. This is now the **sole** entry
point to loadout adjustment; the bag drawer's management mode no longer
carries it.

Drawn as the device: the haft on one side, the seated Movement, and the
Complication sockets as visible slots. Crafted Complications sit in a tray
beside it and are moved into and out of sockets. Charge and capacity read
off the device itself rather than off a progress bar.

Seeding an unseeded Dial and crafting components keep their current
behaviour, reached from this view.

## 5. The Lab bench

Replaces the current picker → pairing → confirm flow. Bench and crafting
rules, costs and probabilities are untouched.

### 5.1 Camera

**A wide plate with snap-to stops.** One long bench image, three focal
stops, arrows step left/right. No free scrolling — a swipe gesture would
fight the ore-dragging (§5.4). The arrows are also the affordance that
there is more bench off-screen.

Stops, left to right: **books → ore containers → apparatus.**

Canvas: **1170 × 844** displayed (3 × 390 wide, full-bleed), authored at
**585 × 422**, displayed 2× nearest.

### 5.2 The two notebooks — mode

The bench opens on the books stop with two notebooks: **Recipes** and
**Experiments**. Tapping one sets the mode. The chosen notebook stays
visibly open/held for the whole session so the mode is never invisible, and
tapping it returns to the fork. The player can switch modes freely.

**Experiments mode**
1. Ore stop: select 1 or 2 ore types.
2. The Experiments notebook is tappable here — a panel of pairings already
   tried and their results, and current recipe levels.
3. Arrow → apparatus stop. Tap an apparatus to run.
4. It animates (§5.5), consumes ore, and reports the outcome.

**Recipes mode** — two paths, both valid:
- **Book path:** tap the recipe book, pick a known recipe *and a quantity*,
  craft.
- **Manual path:** select an ore type at the ore stop, arrow to the
  apparatus, tap the apparatus that matches. Crafts **quantity 1**. This is
  the expert path — craft from memory without opening the book.

In Recipes mode the ore stop is a *receipt*, not a decision, when using the
book path.

### 5.3 Apparatus

Four apparatus, one per approach in `data/approaches.json`, two of which
are room-gated and so **appear on the bench as the property is upgraded**:

| Approach | Apparatus | Gate |
|---|---|---|
| `heat △` | burner | from the start |
| `grinding ◇` | mortar | from the start |
| `compression ▽` | press | Workshop room |
| `distilling ○` | still | Improved Lab room |

Each apparatus has **two ore slots, the second optional** — a type set is
one of the 5 singles or one of the 10 unordered pairs.

**Arming rule (crafting mode):** an apparatus only lights up when the
current ore selection resolves to a **known** recipe on that approach.
Unknown combinations are inert — no error, no ore spent, no wasted tap. The
lighting itself teaches which apparatus a recipe lives on. In experiments
mode any legal selection arms any known approach; that is the whole point
of experimenting.

Every recipe already carries its `discovery: {types, approach}` pair, so
ore + apparatus resolves to exactly one recipe with no new data.

### 5.4 Ore containers

Five containers at the ore stop, one per ore type, each labelled with its
ore symbol and a numeric count. **Three visual states each** — empty /
some / plenty — for 15 sprites.

Selection is **tap-to-select, then tap the apparatus**, as the primary and
always-available path. Drag-and-drop does the same thing and exists as a
flourish, never as the only route: one-handed dragging at 390px fails for
some players, and there is no fallback UI left once the picker is gone.

A selected ore chip must communicate the cost it will incur (a probe costs
3 per type; a craft costs the recipe's own ingredients) so nobody commits
blind.

### 5.5 Animations

One short animation per apparatus, played while the roll resolves: burner
flares, mortar grinds, press descends, still drips. Train (§3.1) gets one
too. These replace the current "Working the bench…" text state.

### 5.6 Inherited constraint — do not violate

`M3-CALC-DISCOVERY.md` §8.0: **the 15 type sets are never enumerated
anywhere in the UI** — not as a matrix, not as a list, not as a completion
tracker. The bench satisfies this better than the old picker did: the
player physically assembles a pairing and it exists only while it is in the
apparatus. The Experiments notebook shows *pairings already tried*, which is
history, not an enumeration. Keep it that way.

Refine (raising a known recipe's tier) is an action **on a recipe page in
the book** — not a fifth apparatus.

## 6. The floorplan

The pinned noticeboard opens an estate agent's plan of the property: filled
room slots, empty room slots, and the rooms available at this tier. This is
where rooms are **bought**, and where **contacts are assigned** to the lab
and vein-cultivation rooms — assigning a person to a room is inherently
spatial, and it is currently buried inside a collapsed section.

The floorplan is how the design scales to a 12-room mansion without 12
rooms of art. Rooms other than the hero room are never places you walk to;
a corridor visible through an open door is **painted depth, not
navigation**.

## 7. The property app

Tier stats and upgrades leave the HQ tab and become a property app on the
Phone tab, alongside `Reynard's` and `VfL` — a parody property portal
listing your current place with its stats (daily cost, raid risk, rooms)
and the next place up, with the upgrade action.

The split is the point: **the phone sells you the place, the room is the
place.** Three distinct commerce surfaces with no duplication — property on
the phone, rooms on the floorplan, security on the door.

## 8. The door

Drawn with visible fixture points: an empty lock plate, an empty bar
bracket, a bare camera mount, an unmarked ward panel. Installed security
fills its slot; uninstalled security is a visible absence you tap to buy.

**Hostile state:** while a raid is pending, the door goes hostile in the
room plate — and tapping it opens Defend rather than the security list.

## 9. Data & degradation

A manifest, `data/hq_visuals.json`, following the `data/combat_visuals.json`
precedent exactly: every plate and sprite has an `image` path that may be
`""`, plus its hit regions.

**An empty path renders a labelled placeholder box in the correct region.**
The entire HQ tab is therefore navigable, tappable and playable with zero
art produced, and every asset lands file-by-file with no code change. This
is how the combat screen survived being specced ahead of its art, and it is
non-negotiable here for the same reason.

Hit regions are hand-authored numbers. Because the agent cannot see the UI
and the human is visual QA, implementation must include a **debug region
overlay** — a toggle drawing every hit region and sprite rect over the art
with its id. Unverified regions are flagged `ART-REVIEW:` in the task report
the same way new copy is flagged `PROSE-REVIEW:`.

## 10. Rollout

**v1 is the bedsit tier only** — one room plate, one lab bench plate, and
*every* zone and sub-view fully built. Tiers 2–6 are art-only follow-ups
against a layout that has already met a thumb. Committing six tiers of art
to an unproven layout is the expensive mistake available here.

Suggested ticket order (dependency-sorted):

1. `hq_visuals.json` manifest + placeholder renderer + debug region overlay.
2. Room view replacing the card stack; zones wired to today's destinations.
3. Property app on the Phone tab; tier/stat cards removed from HQ.
4. Floorplan sub-view (rooms + contact assignment).
5. Door sub-view (security + hostile/Defend state).
6. Lab bench: pan model, stops, mode fork.
7. Lab bench: ore containers, selection, arming rule, both craft paths.
8. Apparatus + Train animations.
9. Dial loadout view; loadout leaves the bag drawer.
10. Bedsit art production: room plate, bench plate, ore containers, sprites.

## 11. Art production notes

- Outlines for tappable objects are **baked into the generated art**, not
  drawn at runtime. Hit regions are measured against the finished plate.
- State variants (with lock / without lock) are produced as **variant
  plates**, and the differing region is cropped manually and spliced in as a
  layer. Registration between base and variant is a manual responsibility
  for now; ART-BIBLE §4's standing rule — *edit the canonical image, never
  re-prompt it* — is the way to keep the drift small enough to crop.
- Everything renders at a **fixed integer scale with nearest filtering**. A
  non-integer scale destroys the pixel grid and the baked outlines with it.

## 12. Open questions (deliberately deferred)

1. **Attention-state outlines.** Baked outlines cannot vary with state, so
   the "bright = something to act on, dim = idle" idea is parked. Revisit
   once the room exists: it is the single strongest argument for a picture
   over a list, and losing it permanently would be a shame.
2. **Decal extraction tooling.** A `base + variant → cropped layer + rect`
   diff tool with drift detection would remove the manual crop step. Not
   needed until the tier-2–6 art run makes the manual cost real.
3. **Tier 2–6 densification.** What each tier's room actually gains, and
   whether the gym and lab stay in the hero room at mansion tier.
4. **Ore store tap.** Recommended default: tapping the bag/strongbox/safe
   opens a readout panel (contents + raid warning). Not yet agreed.
5. **Bag drawer's remaining role** once loadout adjustment leaves it.

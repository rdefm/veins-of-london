# UI Vision — Four Chrome Families

**Status:** Vision + buildable spec, agreed with the human in a grilling
session, 2026-09-09. Supersedes every "parchment" / "ink, paper, amber"
reference anywhere in the docs — that framing is retired outright, not
softened. Where this document and `docs/ART-BIBLE.md` disagree on pixel
technique (grid, canvas sizes, pipeline, render settings), ART-BIBLE still
wins — this document only replaces ART-BIBLE §1's *mood* paragraph (§2
below) and adds the three chrome families ART-BIBLE never covered.

**Prose:** contains no player-facing copy. Nothing here is `PROSE-REVIEW:`
material.

---

## 1. The problem

`combat-animation-vision.md` §9 locked one rule and left it half-applied:
**diegetic props render in pixel art; abstract UI chrome stays vector.**
The pixel half has since been designed in real detail (ART-BIBLE, the HQ
diorama, the combat stage). The vector half never got the same treatment —
`theme/main_theme.tres` styles exactly three control types (Button, Label,
Panel/PanelContainer) with one flat cream-and-amber look, and every screen
that isn't a diegetic pixel plate — the Phone grid, the Dial's tray rows,
combat's action cards, Reynard's ledger, notifications — falls back to
that one undifferentiated skin or, in places, no skin at all. The
screenshots that prompted this doc show the result: a finished room next
to a totally generic app.

The fix isn't "design one better theme." The game already contains at
least four genuinely different *kinds* of screen, and forcing them into
one visual system is what reads as wireframe-flat. Each gets its own
identity instead.

## 2. Family 1 — Physical-world pixel art

**Unchanged in technique.** ART-BIBLE §1–§7 still governs grid, palette
construction, canvas sizes, `pixelize.py`, and render/import settings in
full. This section only replaces ART-BIBLE §1's *mood* paragraph and the
matching lines in §5's prompt template and `data/palette.json`'s
`meta.direction`.

**Retired:** "overcast daylight," "grey sky," "deliberately mundane and
unremarkable, not atmospheric," and every description that reads as
*drab*. None of that was ever the goal — it was a hedge against neon, and
it overcorrected into flatness.

**New mood line:** grounded, realistic London colour. Vivid where the
real city is vivid — brick red, bus/pillar-box red, shopfront paint, park
green, market colour — restrained where it naturally is (concrete,
pavement, an overcast sky is *one* weather state among several, not the
locked default). `data/palette.json` already supports this better than
ART-BIBLE's own prose did — its `brick`, `pastel`, `foliage` and `ore`
groups are not desaturated to grey today and don't need to change; only
the `meta.direction` string and ART-BIBLE's mood paragraph were ever
selling it short.

**Kept:** "not neon, not fantasy-saturated, not dark-noir." The wonder is
that magic hides in an ordinary, vividly real London — not that the world
itself glows. Lighting/weather/time-of-day are now allowed to vary per
scene (a rain-slick Camden night reads differently from a bright Greenwich
morning) rather than every plate sharing one locked overcast/top-left-key
condition — ART-BIBLE §1's lighting-rule sentence ("top-left key light, on
every subject, every plate, always") is superseded; per-plate lighting is
now a legitimate creative choice, decided when that plate is actually
briefed, not fixed in advance. The five ore-accent colours and the
`calc_gold` accent group are untouched by any of this.

**Applies to:** HQ room (all tiers), the Lab bench, the Dial's physical
render, the door, combat backdrop plates, combat sprites/effects.

## 3. Family 2 — Phone-OS chrome

The Phone tab and everything under it — the home grid and every app
(Notes, Factions, The Ticker, Profile, Save/Load, Notifications, Reynard's,
Harrow's, Contacts) — is designed to actually look like using a
contemporary smartphone. Status-bar-style top strip, app-icon grid with
real icon art (not laminated frames), native-feeling list/detail patterns
per app. This is the one family with no bespoke in-fiction material
reference — the joke is that it's *just a phone*, the same as the
player's own.

**Applies to:** everything reachable only through the Phone tab.

## 4. Family 3 — Tube-diagram chrome

The VfL/Map tab. Underground-diagram visual language — already broadly
directed in `VISION.md` §6 and flagged as confirmed-but-unspecified in
`combat-animation-vision.md` §13 item 1. Not further specified here; this
document only registers it as a distinct family so nothing downstream
tries to reuse Phone-OS or field-kit chrome on the Map tab by default.

**Applies to:** the Map/VfL tab only.

## 5. Family 4 — Field-kit HUD chrome

Everything persistent or in-scene that is neither inside a phone app, nor
the tube diagram, nor a literal pixel-art object: the top status bar, the
bottom Phone/Map/HQ nav dock, the combat command deck (action cards,
Complication detail rectangle, the departure-board log), and HQ's
list-style sub-views (the floorplan, Train, the ore-store readout).

**Design principle: an eclectic set of real London signage/object
references, picked per component, not one uniform material.** This family
does not get a single texture the way "parchment" tried to be one — it
gets a curated kit of specific, real things, chosen for fit component by
component. This is deliberate: it's the same design instinct that already
made the HQ room and the Dial work (a specific object beats an abstract
theme), applied to the chrome instead of just the diegetic props.

**Confirmed example:** notifications render as an electronic dot-matrix
departure/platform display — the kind on a real train or Tube indicator
board. Amber-on-black pixel characters, that specific flicker/refresh
character.

**Candidate references for the rest (illustrative, not locked — pick and
confirm per component when that component is actually briefed):**

| Component | Candidate reference |
|---|---|
| Notifications | Electronic dot-matrix departure board — **confirmed** |
| Combat departure-board log | Same dot-matrix family as notifications — the name already implies it |
| Top status bar | Platform/street enamel signage strip |
| Nav dock (Phone/Map/HQ) | — open |
| Combat action cards | — open |
| HQ floorplan | Estate-agent particulars (already the in-fiction frame per `hq-diorama-vision.md` §6) |
| HQ Train panel | — open |
| Ore-store readout | — open |

Filling in the open rows is follow-up work, not blocking on this document
— the principle (real object per component, not a shared material) is
the thing being locked here.

**Shared across the family regardless of per-component reference:** the
palette and accent rules in §6, and the typography in §7.

## 6. Colour rules across all four families

- **`calc_gold` (`data/palette.json`) stays reserved for calc/currency
  reads only** — this was already ART-BIBLE's rule; the screenshots that
  prompted this document violate it (every button is amber regardless of
  meaning) and that's the bug, not the target. Enforced from here on: if
  it's gold, it means calc or cash, full stop.
- **Ordinary buttons/actions across Families 2–4 use a new accent:
  pillar-box/bus red** — Royal Mail red / Routemaster red register.
  Civic-London, not tied to any one faction, and distinct from the
  Underground roundel blue Family 3 will likely want for itself.
  Candidate hex: `#c8102e` (indicative — confirm against
  `data/palette.json`'s existing ramps before locking; needs a new
  `ui_action_red` entry, probably its own `group`, added the same way
  `calc_gold` was, with the swatch regenerated per ART-BIBLE §2's
  documented process).
- Family 1 (pixel art) is governed by §2 above, not this rule — its
  colour is scene-grounded, not accent-driven.
- Family 3 (tube diagram) may need its own accent (roundel blue/red) —
  out of scope here, decided when that family is specified.

## 7. Typography

**Two typefaces total**, shared across all four families rather than one
per family:

1. **One UI sans** — covers all vector chrome: Families 2, 3, and 4 alike.
   Families are differentiated by colour, layout, and per-component object
   reference (§5), never by swapping typeface. Also the answer to
   `combat-animation-vision.md` §13 item 4 and the ore-glyph problem
   `scenes/components/ore_glyphs.gd` already documents (engine fallback
   font can't render the five ore symbols) — the chosen face needs glyph
   coverage or a custom icon-font fallback for the five ore symbols
   specifically.
2. **One bitmap pixel font** — reserved for in-scene labels that render
   *inside* Family 1 pixel-art plates (e.g. a sign painted into a
   backdrop), never for real UI text.

Exact typeface choices: not decided in this document — a follow-up task,
not a blocking design question.

## 8. Rollout

**Recommended order: Family 4 (field-kit HUD) first, then Family 2
(Phone-OS), then Family 1's mood amendment lands opportunistically with
whatever art is next in the pipeline, then Family 3 last.**

Reasoning:

1. **Family 4 is the one actively colliding with in-flight work.**
   `combat-presentation` and `hq-diorama` are live ticket folders — the
   combat command deck was just relaid out (ticket 18, 2026-09-09, see
   `combat-animation-vision.md` §2.5's "Superseded" note) and the HQ
   floorplan/Train/ore-readout sub-views are mid-build. Every one of
   those screens is being decided ad hoc, right now, without this family
   spec'd — exactly the "cheapest moment to set the standard, most
   expensive to retrofit" situation `combat-animation-vision.md` §11
   already named. Detailing Family 4 next stops that drift.
2. It's also the least defined — 6 of 8 rows in §5's table are still
   "open" — and the riskiest creative bet in this whole document (an
   eclectic per-component object kit instead of one material). Better to
   pressure-test it in detail before more screens ship against a vague
   version of it.
3. **Family 2 (Phone-OS) is the fast, safe win after that.** No bespoke
   research needed (it should just look like a real phone, a
   well-understood target), touches the most individual screens (8 apps +
   home grid), and every one of them is currently flat-grey placeholder —
   highest visible-improvement-per-effort once Family 4 stops moving
   under it.
4. Family 1 needs no new *design* work, only the mood-paragraph patch
   already applied to ART-BIBLE above — it rides along with whatever art
   gets commissioned next rather than needing its own pass.
5. Family 3 already has the most existing implementation (the Network map
   systems are largely built and shipped per `CODEMAP.md`) and the least
   pressure to change — lowest priority to *re*-detail right now.

## 9. Open items

- Field-kit HUD per-component object references (§5 table) — fill in as
  each component is actually briefed.
- `ui_action_red` hex + palette entry, swatch regen.
- Family 3 (tube diagram) accent colour and full spec — not attempted
  here.
- Typeface selection for both the UI sans and the pixel font.
- Family 2 (Phone-OS) has no bespoke spec yet beyond "look like a real
  phone" — needs its own detailing pass (icon grid, list/detail patterns,
  per-app layout) the way HQ and combat got.

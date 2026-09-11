# UI Vision — Four Chrome Families

**Status:** Vision + buildable spec, agreed with the human in a grilling
session, 2026-09-09; Family 4 detailed in a further grilling session,
2026-09-10 (§5 below). Supersedes every "parchment" / "ink, paper, amber"
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

"Notifications" here is the full-history log app (a phone-native
list/detail screen) — distinct from the live dot-matrix notification board
that now renders persistently above every screen regardless of tab
(Family 4, §5).

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
the tube diagram, nor a literal pixel-art object: the top status
bar/notification board, the bottom Phone/Map/HQ nav dock, the combat
command deck (action cards, Complication detail rectangle, the
departure-board log), and HQ's list-style sub-views (the floorplan, Train,
the ore-store readout).

**Design principle (amended 2026-09-10): an eclectic set of real London
signage/object references, picked per component where the object *is*
the information — not one uniform material, and not every component.**
This family does not get a single texture the way "parchment" tried to be
one — it gets a curated kit of specific, real things, chosen for fit
component by component, the same instinct that already made the HQ room
and the Dial work (a specific object beats an abstract theme). But a
bespoke citation is not mandatory for every row: ordinary controls that
have no inherent diegetic identity (the combat action cards, the HQ Train
panel) share one plain field-kit button/panel treatment built from §6/§7's
already-locked palette, accent and typography rules, rather than each one
forcing an artifact of its own. Reserve real-object references for
components where the object genuinely carries information or character —
a departure board *is* a message queue, an estate agent's particulars
*is* a property listing — not for a generic Attack/Item/Run button.

**No unifying owner (resolved 2026-09-10):** the kit does not belong to
one in-fiction person or organisation (not the player's own gear, not a
Conclave-issued manual) — "eclectic real London objects, tied together by
§6/§7's shared rules" is sufficient coherence on its own, the same way
Family 1 stays coherent across many real-world subjects without being one
person's possessions. This is also provably necessary, not just
permitted: the HQ floorplan's already-locked "estate-agent particulars"
reference (§6 of `hq-diorama-vision.md`) is an outsider's document, not
something the player would own, so a single-owner framing was never
achievable without a retrofit.

**The departure-board group — status bar, notifications, and the combat
log are one material, confirmed dot-matrix (resolved 2026-09-10):**

- **Notifications render as an electronic dot-matrix departure/platform
  display** — the kind on a real train or Tube indicator board,
  amber-on-black pixel characters. This was already confirmed pre-session;
  what's new below is how it's built and where it lives.
- **The top status bar and the notification board are the same physical
  object.** Day/time-blocks, cash and the bag button sit on the board's
  larger top line; below that, unseen notifications render as smaller
  numbered rows ("1st ...", "2nd ..."), styled after a real multi-line
  Tube departure board — same reference (2026-09-10 session), not a
  separate signage strip. They stay **two logical components** —
  `top_bar.gd` and the notification renderer (replacing
  `notification_toast.gd`'s current cream/amber card styling) — mounted
  together so the board reads as one object when both are present, but
  independently positionable so notifications don't disappear if the
  status line ever needs to hide on some future screen.
- **The board is unconditionally persistent on every in-game screen**,
  including `map` (Family 3's own top-of-screen furniture, once
  specified, sits below this board rather than replacing it — Family 3
  can assume status/notifications are already handled and use its own top
  area for tube-diagram concerns like filters/search) and every HQ
  full-bleed sub-view (Lab bench, Dial, Floorplan, Door). It only hides on
  `title`/`intro` (no player state exists yet to show). This is a
  deliberate override of `hq-diorama-vision.md` §3.3's "top bar... auto-hide
  while you are inside one" rule for those four screens — amended there in
  the same pass as this document, see that section's own note. The
  bottom nav dock's hide-on-full-bleed behaviour is **unchanged** — this
  override applies only to the top board.
- **Combat's departure-board log is the same dot-matrix family** —
  confirmed, reinforced by combat-presentation ticket 21 already calling
  it the "ticker."
- **Rendering technique:** a custom `_draw()`-based dot-matrix grid — a
  small hardcoded bitmap-font table (5×7-style cells, just the character
  set actually needed) drawn as amber dots on black, per character. This
  follows the project's existing precedent for "the engine can't render
  this glyph" (`scenes/components/ore_glyphs.gd`'s hand-drawn ore symbols)
  rather than sourcing/importing a dot-matrix font asset — no font ships
  in this repo today, and a static font glyph can't cleanly drive the
  scramble behaviour below.
- **Scramble-on-refresh is in scope; per-dot flicker/strobe is optional,
  not required.** When the board's text changes, characters may
  briefly scramble through other glyphs before settling — the effect a
  real departure board has when it updates. The steady-state flicker real
  LED boards have (constant per-dot strobing even when the text is
  static) is a nice-to-have, not a requirement — the frame, font and
  amber-on-black colour reading correctly as a real Tube indicator board
  is the priority.

**Toasts and modals:**

- **Toasts are not a separate object.** `notification_toast.gd` *is* the
  live notification renderer — it's the same dot-matrix board described
  above, not a second thing needing its own reference.
- **The shared `ModalLayer` (`modal_layer.gd`) dialog card is out of
  scope here.** It's family-agnostic plumbing used by every screen
  regardless of family (Phone's `sell_menu`, HQ's `hq_ore_readout`,
  combat's `combat_setup`, …) — it gets one generic vector-chrome
  treatment, not owned by any single family, the same precedent §7 sets
  for shared typography. Not specified further in this document.

**Component table:**

| Component | Reference / chrome |
|---|---|
| Notifications + top status bar | Merged into one electronic dot-matrix departure/platform board — **confirmed**, unconditionally persistent (see above) |
| Combat departure-board log | Same dot-matrix family — **confirmed** |
| Nav dock (Phone/Map/HQ) | TfL's own site — the "Live arrivals / Maps / Nearby" tile row: flat white tile strip, thin dividers, icon-over-label. Shared UI sans (not TfL's Johnston face, per §7's one-typeface rule), `ui_action_red` in place of TfL's brand blue (already reserved for Family 3, §6) |
| Combat action cards | Generic Family-4 chrome, no bespoke object — exact button styling (corners, border weight, fill) deferred to implementation |
| HQ floorplan | Estate-agent particulars (already the in-fiction frame per `hq-diorama-vision.md` §6) |
| HQ Train panel | Generic Family-4 chrome, no bespoke object; carries `combat-presentation`-pattern ticket 08's training animation — no workout-app visual mimicry |
| Ore-store readout | A handwritten inventory slip — running totals per ore type, in hand, the kind of thing someone updates every time stock moves. The existing raid-warning line (`_build_hq_ore_readout()`) rides the same slip rather than a separate element |

Every row is now resolved. What's left is implementation detail, tracked
in §9.

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
  Locked hex: `#c8102e`, `ui_action_red` in `data/palette.json` (own
  `group: "ui_action"`, added the same way `calc_gold` was; swatch
  regenerated per ART-BIBLE §2's documented process).
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
2. It's also the least defined — 6 of 8 rows in §5's table were still
   "open" at the time this reasoning was written — and the riskiest
   creative bet in this whole document (an eclectic per-component object
   kit instead of one material). Better to pressure-test it in detail
   before more screens ship against a vague version of it. (Resolved
   2026-09-10 — every row in §5's table now has a confirmed answer.)
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

- ~~Field-kit HUD per-component object references (§5 table)~~ —
  **resolved 2026-09-10**, every row confirmed.
- Dot-matrix bitmap-font table — authoring task: pick the cell grid
  (5×7-style) and the actual character set needed (letters, digits, common
  punctuation), then the custom `_draw()` renderer against it. Implementation
  follow-up, not a design question.
- Per-dot flicker/strobe on the dot-matrix board — optional, may slip if
  costly; scramble-on-refresh is the locked minimum (§5).
- Generic Family-4 button/panel chrome (combat action cards, HQ Train
  panel) — the *that it's generic, not bespoke* is locked; exact visual
  styling (corners, border weight, fill) is not, implementation follow-up.
- Family 3 (tube diagram) accent colour and full spec — not attempted
  here.
- Typeface selection for both the UI sans and the pixel font.
- Family 2 (Phone-OS) has no bespoke spec yet beyond "look like a real
  phone" — needs its own detailing pass (icon grid, list/detail patterns,
  per-app layout) the way HQ and combat got.
- Shared `ModalLayer` (`modal_layer.gd`) generic vector-chrome treatment —
  deliberately out of scope here (family-agnostic plumbing, §5).
- File a ticket to rename "Run" → "Leg it" in `combat.gd`'s
  `_build_action_bar()` — `PROSE-REVIEW`, flagged during the 2026-09-10
  session but not decided here (this document carries no player-facing
  copy).

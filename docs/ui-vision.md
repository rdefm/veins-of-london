# UI Vision — Four Chrome Families

**Status:** Vision + buildable spec, agreed with the human in a grilling
session, 2026-09-09; Family 4 detailed in a further grilling session,
2026-09-10 (§5 below); Family 2 detailed 2026-09-11 (§10 below, pending
human confirmation per that section's own note); Event/dialogue cards
detailed 2026-09-12 (§11 below). Supersedes every "parchment" / "ink, paper, amber"
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
construction, canvas sizes, and render/import settings in full. This section only replaces ART-BIBLE §1's *mood* paragraph and the
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

**Detailed component-level spec: §10.**

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
  bottom nav dock remains visible on every HQ sub-view, so the player can
  leave through Phone, Map, or HQ. This override otherwise applies only to
  the top board.
- **Combat's departure-board log is the same dot-matrix family** —
  confirmed, reinforced by combat-presentation ticket 21 already calling
  it the "ticker." **Amended 2026-09-11:** the *mid-fight* ticker no
  longer renders as its own component under the stage — its lines route
  into the top board's notification rows instead, one shared object.
  This requires the board's combat-suppression rule (state.combat.active
  → queue and hold) to be narrowed: entries sourced from the combat log
  bypass suppression and render live, while other notification sources
  still queue/drain as before. The **post-combat outcome log** (the full
  recap shown once the fight resolves, alongside the outcome button)
  stays a separate component, unaffected by this — it's a full-screen
  recap, not a live ticker feed, and doesn't fit the board's 2-row
  format. See `.scratch/field-kit-chrome/issues/03-combat-log-dot-matrix-reskin.md`.
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
| Combat departure-board log | Mid-fight ticker merges into the top board (amended 2026-09-11, see §5 above); post-combat outcome log stays its own dot-matrix-family component |
| Nav dock (Phone/Map/HQ) | TfL's own site — the "Live arrivals / Maps / Nearby" tile row: flat white tile strip, thin dividers, icon-over-label. Shared UI sans (not TfL's Johnston face, per §7's one-typeface rule), `ui_action_red` in place of TfL's brand blue (already reserved for Family 3, §6) |
| Combat action cards | Generic Family-4 chrome, no bespoke object — exact button styling (corners, border weight, fill) deferred to implementation |
| HQ floorplan | Estate-agent particulars (already the in-fiction frame per `hq-diorama-vision.md` §6) |
| HQ Train panel | Generic Family-4 chrome, no bespoke object; carries `combat-presentation`-pattern ticket 08's training animation — no workout-app visual mimicry |
| Ore-store readout | A handwritten inventory slip — running totals per ore type, in hand, the kind of thing someone updates every time stock moves. The existing raid-warning line (`_build_hq_ore_readout()`) rides the same slip rather than a separate element |
| Event/dialogue cards (`scenes/screens/event.gd`) | Generic Family-4 chrome, no bespoke object, plus a persistent pixel-art image slot — **detailed spec: §11** |

Every row is now resolved. What's left is implementation detail, tracked
in §9.

**Shared across the family regardless of per-component reference:** the
palette and accent rules in §6, and the typography in §7.

## 6. Colour rules across all four families

- **`calc_gold` (`data/palette.json`) stays reserved for calc/currency
  reads only** — this was already ART-BIBLE's rule; the screenshots that
  prompted this document violate it (every button is amber regardless of
  meaning) and that's the bug, not the target. Enforced from here on: if
  it's gold, it means calc or cash, full stop. **One narrow, documented
  exception (§11):** a "craft" event card may also carry `calc_gold` panel
  styling, since crafting is inherently a calc-spend action — scoped to
  that one card type only, not a general loosening of this rule.
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
- ~~Family 2 (Phone-OS) has no bespoke spec yet beyond "look like a real
  phone" — needs its own detailing pass (icon grid, list/detail patterns,
  per-app layout) the way HQ and combat got.~~ — **resolved 2026-09-11**,
  see §10 (pending the human confirmation that section's own note flags).
- ~~Event/dialogue cards (`scenes/screens/event.gd`) hardcode their own
  placeholder amber/danger constants, never assigned to a family~~ —
  **resolved 2026-09-12**, see §11.
- Shared `ModalLayer` (`modal_layer.gd`) generic vector-chrome treatment —
  deliberately out of scope here (family-agnostic plumbing, §5).
- File a ticket to rename "Run" → "Leg it" in `combat.gd`'s
  `_build_action_bar()` — `PROSE-REVIEW`, flagged during the 2026-09-10
  session but not decided here (this document carries no player-facing
  copy).

## 10. Family 2 — Phone-OS chrome, detailed spec (session 2026-09-11)

Companion pass to §5, closing the gap §9 flagged. Appended rather than
inserted between §3 and §4 so every existing `§5`/`§6`/`§7`/`§9` reference
already scattered across the codebase and other docs keeps pointing at the
right section — see §3 for the pointer into this one. Scope matches the
ticket that requested it: home-grid icon/tile treatment, the list/detail
pattern, per-app layout conventions, and accent colour(s), reconciled
against §6 (colour) and §7 (typography) rather than inventing either afresh.
**Design note only — no code changed by this pass.** Per the ticket's own
acceptance checks, this needs human confirmation before any implementation
ticket (the roster this section anticipates as "08/09") starts.

**Design principle: it's a phone, not a Vein-branded object.** §3 already
frames Family 2 as "the same [phone] as the player's own" — the one family
with no in-fiction material reference. That's a colour argument, not only a
tone one: where Family 1 is grounded-London warmth and Family 4 is a
curated kit of specific real *London* objects, Family 2 should read as
generic, mass-market consumer electronics — cool neutral greys/near-black,
never `data/palette.json`'s warm neutral group (`outline_black`,
`shadow_deep`, `neutral_mid`, …), which stays Family 1's own. Concretely:
Family 2 runs a **dark "device" shell, top to bottom** — home grid and
every app content screen alike — the way most real phones default today.
This also reads cleanly against the persistent Family-4 board above it
(amber-on-black dot-matrix, §5) instead of visually fighting it the way the
current bright cream sheet does.

**Home-grid icon/tile treatment.** This is `scenes/components/app_tile.gd`
— confirmed (CODEMAP, `nav_bar.gd`'s own header comments) to be exclusively
the phone home-grid's component today, not shared with the Family-4 dock
any more: `nav_bar.gd` forked its own `_DockTile`/`_TileIcon`/`_LockBadge`
classes away from `AppTile`, its own comments noting that `AppTile`'s
cream rounded-frame tile is Family 2 (Phone-OS) chrome now that the
families are split out, not the dock's (field-kit-chrome ticket 04). That
means `AppTile`'s current `FRAME_BG_COLOUR`/`ACTIVE_BG_COLOUR`/
`ACTIVE_BORDER_COLOUR` cream-and-tan constants are exactly the leftover
placeholder this ticket exists to replace, free to change without touching
the dock.

- **Tile ground:** drop the cream/tan frame per tile; the whole home-grid
  surface is one flat cool near-black (indicative `#1b1b1d`), icons sitting
  directly on it the way a real launcher's icons sit on a wallpaper, not
  each icon in its own laminated card.
- **Icon art is real, bespoke, per-app artwork — not a shared monochrome
  glyph set (revised same session, direct human steer: the apps should
  look like genuine, distinct apps, the way a real phone's home screen
  does — each with its own icon, supplied by Richard and wired in as each
  one lands).** This reverses this section's first draft, which had
  proposed one flat ink-coloured glyph style shared across all nine icons
  specifically to avoid needing a third accent colour. That concern doesn't
  apply here: icon art is bespoke per-app artwork, the same category §6
  already carves Family 1's pixel art out of ("Family 1 ... is governed by
  §2 above, not this rule — its colour is scene-grounded, not
  accent-driven") — each icon is free to carry its own full colour and
  identity (Reynard's can be fox-orange, Harrow's brick-red, The Ticker
  newsprint-grey, whatever the art itself calls for) without that reading
  as a rogue fifth accent, because it isn't UI-accent colour at all, it's
  content, the same way a photo in a Contacts avatar wouldn't be. `§6`'s
  `calc_gold`/`ui_action_red` rule keeps governing this family's *chrome*
  (buttons, badges, dividers, meters) exactly as written — it was never a
  restriction on artwork.
- **Asset contract (existing, no change needed):**
  `docs/adr/0003-app-icon-asset-contract.md` already covers exactly this —
  `res://assets/icons/apps/<app_id>.png`, square, 128×128, alpha PNG.
  `AppTile.load_icon()` already resolves each id independently and falls
  back to the app's label text when no file exists yet — so supplying icons
  incrementally, one `.png` at a time, needs no ticket and no code touched
  per icon; each file just lands at its id's path and the next run picks it
  up. This section adds one **implementation note the fallback path needs**
  that wasn't true before: once real art exists for an id, `AppTile` should
  suppress its own background panel/border for that tile rather than
  drawing `FRAME_BG_COLOUR` behind it — real art is expected to be a
  full, self-contained square (its own background baked in, whatever
  shape/corner treatment the art itself uses), and a mismatched panel
  colour would peek through any transparent corners. The dark-badge
  background stays exactly as drafted above, but only for ids still on the
  label fallback.
- **Style brief for the art itself (guidance, not a lock — Richard's call
  as the one drawing them):** square, full-bleed, self-contained
  (background baked in, not a transparent glyph expecting a shared tile
  colour behind it) — a genuine icon, not a sprite. Keeping rendering
  technique roughly consistent app-to-app (all flat/vector-illustrated, or
  all one shared lighting logic, etc.) will read as one coherent OS rather
  than nine found icons from different packs, the same instinct that keeps
  Family 1 coherent across many real-world subjects (§5) — but this is a
  recommendation to keep in mind while drawing, not a rule to check
  against.
- **Badge dot** (unread/attention): `ui_action_red`, exact locked hex
  `#c8102e` — today's `BADGE_COLOUR` constant is a close-but-not-exact
  approximation of the same red; align it to the locked value while this
  component is being touched anyway.
- **Locked overlay:** unchanged — the existing muted-grey padlock
  (`LOCKED_TINT`, `Icons.draw_padlock`) is family-agnostic disabled-state
  styling, not part of this pass.
- `AppTile`'s `active`/`ACTIVE_BG_COLOUR`/`ACTIVE_BORDER_COLOUR` path is
  dead weight from before `nav_bar.gd` forked away (nothing in `phone.gd`
  passes `active` today) — noted for whoever picks up the implementation
  ticket, not a design question, and not this ticket's job to remove.

**App-content shell (every screen past the grid, i.e. everything
`_phone_back_button()` already fronts):** one shade up from the home-grid
black — indicative `#252528` — so an open app reads as content raised over
the home-screen wallpaper, the same layering a real phone uses. Heading +
back-chevron stay top-left, matching the drill-down navigation
`PhoneNav`/`_phone_back_button()` already implement; this section only
specifies the paint, not new navigation structure. Hairline row/section
dividers: a low-contrast cool grey (indicative `#424246`). Primary text
near-white (`#ededee`); secondary/muted text a mid cool grey (`#999a9d`) —
the same job `UI.muted_label()` already does, just recoloured.

**Per-app layout conventions.** The nine apps split into four existing
shapes, not one — confirmed against `scenes/screens/phone.gd`'s actual
`_build_*` functions rather than assumed from the app names alone. Each
shape gets one shared chrome treatment; no per-app bespoke object the way
Family 4 sometimes reaches for one (§5's principle explicitly doesn't
apply here — Family 2's whole point is that it has none).

| App | Shape today (`phone.gd`) | Chrome |
|---|---|---|
| Notes | Sectioned checklist (`_build_notes`) | Flat-list pattern: section heading, hairline-divided checklist rows, tick glyph in ink, no push-navigation |
| Factions | Flat directory (`_build_factions`, one card per faction) | Flat-list pattern: row per faction, name + reputation meter inline. Meter fill is **ink, not `ui_action_red`** — §6's accent is for actionable elements, a reputation readout is passive data, same restriction `calc_gold` already has for calc/cash |
| The Ticker | List → detail (`_build_headline_card` → `_build_axis_detail`) | List/detail pattern (below): headline row → axis detail screen, push/pull buttons in `ui_action_red` |
| Contacts | List → detail (contact list → `_build_conversation` thread) | List/detail pattern (below), thread view as message bubbles: outgoing bubble filled `ui_action_red` (light text), incoming bubble flat dark-grey fill (`#333336`-ish, light text) — ordinary two-party messaging convention, no new accent needed |
| Profile | Stat cards (`_build_profile_stats_card`, `_build_profile_skills_card`, `_build_profile_equipment_card`) | Dashboard pattern: label/value rows grouped in cards, ink throughout — no currency shown here (`phone.gd`'s own `_build_profile` comment: cash/day is deliberately excluded, the status bar already shows them), so no `calc_gold` on this screen |
| Save/Load | Slot rows + action cards (`_build_save_slot_row`, export/import/new-game cards) | Action-list pattern: row = slot summary + inline buttons. Save/Load buttons filled `ui_action_red`; Delete/New-Game (destructive/irreversible) rendered as a lower-weight outline button instead of a second "danger" accent — de-emphasis via weight, not a new colour |
| Notifications | Flat log (`_build_notification_row`) | Flat-list pattern, newest-first, no push-navigation — this is the full-history log app §3 distinguishes from the persistent dot-matrix board (Family 4) |
| Reynard's | Balance + flat log (`_build_balance_card`, `_build_bank_transaction_row`) | Dashboard pattern for the balance card (figure in `calc_gold`) + flat-list pattern for the transaction rows below it (amounts in `calc_gold`, everything else ink) |
| Harrow's | Two comparison cards (`_build_property_current_card`, `_build_property_next_card`) | Dashboard pattern: current-tier and next-tier cards stacked. `£` figures in card body text use `calc_gold`; the "Move for £X" action button stays standard button ink-on-`ui_action_red` (gold-on-red would fail contrast) |

**List/detail pattern** (Ticker, Contacts): master rows are flat,
hairline-divided, no card border per row — title line in ink, one muted
secondary line, trailing meta right-aligned where relevant (e.g. a
timestamp). Tapping a row pushes a detail screen using the same
app-content shell and back-chevron already described above; nothing about
the *mechanism* changes; this section only specifies row and header paint.

**Reconciled against §6:** no third *accent* introduced — `calc_gold` and
`ui_action_red` still cover everything this family's chrome does.
`calc_gold` stays exactly what §6 already says — calc/currency reads only
(Reynard's, Harrow's, nowhere else in this family). `ui_action_red` is
reused, not reclaimed from Family 4 — §6 already scoped it to "ordinary
buttons/actions across Families 2–4" collectively; the ticket's framing
("already claimed by Family 4") describes what's implemented so far, not
an exclusive lock. The one new rule this section adds on top of §6:
**`ui_action_red` marks actionable elements only, never a passive data
readout** (reputation meters, log rows) — the same restriction §6 already
places on `calc_gold`, generalised. Per-app **icon art** is explicitly
outside this rule, same carve-out §6 already gives Family 1 — see the
home-grid treatment above.

**Reconciled against §7:** no new typeface. All of this rides the same one
shared UI sans §7 already locks for Families 2–4, applied through the same
`UI.*` helpers (`UI.heading()`, `UI.label()`, `UI.muted_label()`,
`UI.card()`, `UI.button()`, `UI.checklist_row()`) `phone.gd` already calls
throughout — this section only recolours what those helpers render, it
doesn't touch font choice or introduce new text components.

**Deferred to implementation, not decided here:** exact hex values above
are indicative, not locked the way `ui_action_red`'s hex is in §6 — pick
final values when the implementation ticket lands and lock them the same
way. Real per-app icon glyph art (the nine `.png` files the asset contract
expects). Exact corner radius/spacing now that the frame border is gone.

## 11. Event/dialogue cards, detailed spec (session 2026-09-12)

Closes the gap flagged in `.scratch/ui-chrome-pass/issues/10-events-ui-design-spec.md`:
`scenes/screens/event.gd` (the generic event-card screen driven by
`state.event`, covering district events and story-beat events alike)
hardcodes its own `AMBER_COLOR`/`AMBER_BG`/`DANGER_COLOR` constants, never
touched by any family reskin, and §5's table never assigned it anywhere.
**Design note only — no code changed by this pass.**

**Family: Family 4, generic chrome, no bespoke object.** §5's own
definition of Family 4 ("everything persistent or in-scene that is neither
inside a phone app, nor the tube diagram, nor a literal pixel-art object")
covers the event screen by construction — this isn't a fresh family
decision, just applying the definition. Within Family 4, this lands in the
"no inherent diegetic identity" bucket alongside combat's action cards and
the HQ Train panel, not the "curated real-object reference" bucket
(departure board, estate-agent particulars): an event card is a plain
content container, not an object that itself carries information. Entries
keep their current boxed-panel shape (`UI.card()`) — not Family 2's
chat-bubble pattern — since event prose runs long and mixes label/speaker/
body in ways a bubble shape handles poorly; only the palette changes.

**Card-type-by-card-type treatment** (the six types `systems/events.gd`'s
schema supports: narration, speaker, tension, resolution, craft, choice):

| Type | Treatment |
|---|---|
| narration | Plain `UI.card()`, cream fill, no accent. Unchanged. |
| speaker | Plain card + bold heading (`UI.heading()`) for the speaker name above the body text. Mechanism unchanged from today. |
| tension | Plain cream fill kept; the border/left-stripe recolours to the *shared* `MapStyle.DANGER_COLOUR` constant (not a private duplicate — `event.gd`'s current `DANGER_COLOR` is numerically identical to it already, so this is a wiring fix, not a redesign) — matches the danger idiom already used in `map.gd`/`vein_list.gd` (tinted warning text/rings), rather than inventing a bespoke event-only danger treatment. The tinted-cream fill is dropped; only the border carries the accent. |
| craft | Amber panel **kept**, per the documented §6 exception above — border `calc_gold`, fill `calc_gold_light` (`data/palette.json`), replacing the old private `AMBER_COLOR`/`AMBER_BG` constants with the named, shared palette entries. |
| resolution (synthetic entry spliced in after a resolved choice, `Events.revealed_cards()`) | Identical to narration, no marker — it already reads as a direct continuation of the choice moment. |
| choice | Prompt renders like narration/speaker (see bug fix below); the `choices` become action-bar buttons, exactly as today — no layout change. |

**Bug fix folded into this pass:** `_build_card()`'s `match card["type"]`
only renders the `speaker` field for `type:"speaker"` cards today. A
`type:"choice"` card also carries an optional `speaker` field per the
M1-LONDON D5 schema addition, but it's currently silently dropped (falls
into the plain default case). Fixed alongside the reskin: choice cards
with a `speaker` field render the name the same way speaker cards do.

**Action bar (Continue / Rewind / choice buttons):** all three recolour
from the theme's default amber button fill to `ui_action_red`, matching
the precedent already shipped in `combat.gd`'s action cards (§5's
component table). No separate colour for Rewind — it's an ordinary action
button, not a bespoke mechanic-specific accent; the codebase has no
existing precedent for a distinct "rewind colour" anywhere it already
appears (combat's own rewind replay is uncoloured too).

**New: persistent event image slot.** Not part of the original card
schema — added by this pass to support inline illustration on some events
(e.g. story beats), which no prior family spec covers.

- **Schema:** any revealed entry — including a choice's synthetic
  resolution entry — may carry an optional `image` key: an asset path
  string, or explicit `null` to clear the slot. Omitting the key entirely
  first checks for the card's convention-named asset, then means "no change"
  when none exists — the slot keeps showing the last image. This is derived
  state, computed from the cards up to the current position — not a new field
  on `state.event` itself, so
  Rewind restores it for free (it already snapshots `cardIndex` and
  `choiceResults`, which is all this derivation needs).
- **Art:** Family 1 pixel art, ART-BIBLE pipeline — this is diegetic
  illustration content sitting inside a vector-chrome document, same
  split ART-BIBLE §1/`combat-animation-vision.md` §9 already draws
  everywhere else in the game.
- **Size/framing:** a **fixed-height thumbnail**, not the full 390×360
  backdrop-plate proportions (which would eat ~40% of the 844px viewport,
  same footprint as a combat backdrop) — indicative 160–180px tall, exact
  value deferred to implementation. Full content width, inset within the
  same 16px side margins the entry cards below it use, with a thin ink
  border — reads as an illustration inserted into a document, not a scene
  bleeding off-screen the way a combat backdrop does.
- **Placement:** a fixed, non-scrolling region between the persistent
  top status/notification board (§5) and the scrollable entry stack.
  Collapses to zero height when no revealed entry has specified an image
  yet — an event authored with no art looks exactly as it does today.
- **Asset path convention:**
  `res://assets/events/<event_id>/<event_id>_card<n>.<extension>`, where
  `<n>` is the one-based card index and `<extension>` is lowercase `png`,
  `jpg`, `jpeg`, or `webp`. Explicit JSON `image` values remain supported,
  matching the existing per-domain folder convention (`assets/combat/
  <enemy_id>/`, `assets/hq/regions/`, `assets/hq/dial/`).

**Reconciled against §6:** no third accent introduced. `ui_action_red`
reused exactly as already scoped ("ordinary buttons/actions across
Families 2–4"). `calc_gold` stays calc/cash-only except the one documented
craft-card exception above. `MapStyle.DANGER_COLOUR` is an existing
app-wide colour (raid warnings, collapsed-vein warnings, the map's danger
ring) being reused here, not a new one.

**Reconciled against §7:** no new typeface. Rides the same shared UI sans
through the same `UI.*` helpers `event.gd` already calls
(`UI.card()`, `UI.heading()`, `UI.label()`, `UI.muted_label()`,
`UI.button()`).

**Scope:** this design change (including the image-slot schema addition)
folds into ticket 11's implementation pass rather than splitting into a
follow-up ticket — see that ticket's updated acceptance checks.

**Deferred to implementation, not decided here:** exact image-slot height
within the 160–180px indicative range; exact craft/tension border weight
and corner radius; the schema-comment update atop `systems/events.gd`
(currently documents the pre-image card shape) needs to gain the `image`
key once implemented.

### Readable day clock — day rhythm ticket 01

The shared departure board reserves 80px below the current safe-area inset. Row 0 shows a sun/moon cue, full day number and full phase name; row 1 shows three phase markers and cash. Both use 2px dots, retaining two notification rows below and the existing bag-button exclusion. At 390px, Day 150 Afternoon and five-digit cash fit on their separate rows. Completed phases use a check, the current phase a filled centre square, and remaining phases hollow squares; colour is not needed to distinguish them.

Available paid actions display "last block today" during Evening. Blocked/free actions omit the time-cost suffix. Rest explicitly says "next morning"; its caption and available experiment cost remain visible over finished diorama artwork. Copy/cues live in `data/constants.json.dayClock`. Mechanics, automatic rollover and daily-tick order are unchanged.

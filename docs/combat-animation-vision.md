# Combat Animation & Art Direction — Vision

**Status:** Draft from a design session (2026-08-26), revised in a second
grill-me pass (2026-08-29 — layout/UI branch; the aesthetic-theme/art-style
branch continues in a fresh session per §14). Written against `collective1`.
Combat-scoped by decision; §11 flags the wider art-direction opportunity but
does not attempt to settle it.

**Scope of authority:** this document is canonical for **combat presentation**
— battle grammar, sprite budget, animation technique, asset pipeline and the
render settings pixel art requires. It does not define mechanics; every number
in combat still lives in `docs/REFERENCE.md` §3.7 and `data/enemies.json`.
**§2.3 flags two mechanic changes this pass surfaced** (squad combat pulled
forward, turn-based resolution) that this document requires but does not
itself specify — those need their own `REFERENCE.md` work before
implementation.

Where it conflicts with `docs/VISION.md` on art direction, **this document
wins** and VISION.md must be amended in the same ticket that lands the first
pixel asset (§12), per the project constitution.

**Tone note:** the 2026-08-29 session also produced a narrow, scoped amendment
to `CONTENT-GUIDE.md` §3.1 (Pratchett-register whimsy permitted in item
flavour text and rare flourish moments only — never in the combat log, enemy
framing, or any narrator/character dialogue, which stay strict Adams-dry).
That edit is already landed; noted here because it was decided as part of
this combat-visuals conversation.

**Prose:** contains no player-facing copy. Nothing here is `PROSE-REVIEW:`
material.

---

## 1. The decision

Combat moves to **full sprite-frame pixel art** — visible player, allies and
enemies, idle loops, and per-action animation. This supersedes the previous
plan of record.


The reference direction is contemporary indie pixel art as a *technique*
only — a genuine pixel grid, limited palette, dithered shading, no vector or
cel-shaded linework, no smooth anti-aliasing. Nearest technical cousins:
**Backbone**, **NORCO**, **The Last Night**, **Eastward**. Detail density is
not a target.

**Mood and brightness (locked 2026-08-29 continuation, via Gemini image-gen
test):** the game does not inherit these references' dark-noir default.
Locked direction is overcast daylight, muted/desaturated colour (brick red,
weathered pastel shopfronts, grey sky), damp pavement reflecting sky rather
than neon or rain — deliberately mundane and unremarkable rather than
atmospheric. This is the visual expression of the tone bible's "administrative
wonder" (`CONTENT-GUIDE.md` §3), not a whimsical or colourful register —
consistent with §3.1's whimsy carve-out staying confined to item flavour text
and flourish moments, not the stage itself.

## 2. Battle grammar — the portrait problem

Bravely Default, Octopath Traveler, Sea of Stars, Cassette Beasts and Chained Echoes all use a
**horizontal battle line**. The viewport is **390×844 portrait**
(`project.godot`), so that grammar is unavailable and must not be half-copied.

| Grammar | Reads as | Precedent | Verdict |
|---|---|---|---|
| **Stacked bands** | Enemy band in the upper third facing down-camera; player + ally band lower, three-quarter back-turned. Depth comes from scale and backdrop perspective, not screen width. | **Octopath Traveler: Champions of the Continent** — Octopath's own art solving this exact problem in portrait mobile. Fire Emblem Heroes. | **Adopt** |
| Enemy-only front view | Camera *is* the player. Cheapest, most portrait-native. | Dragon Quest, Etrian Odyssey | Rejected — loses the player representation this work exists to add |
| Isometric diorama | Combatants placed in a receding scene. | Into the Breach, Final Fantasy Tactics, Fell Seal | Rejected for combat: iso needs multiple facings per sprite, 3–4× cost |

**2026-08-29 refinement — diagonal fan within each band.** Stacked bands
stays the adopted top-level grammar (enemy band up, player+ally band down).
Within each band, its up-to-3 combatants (§2.2) are **not** laid out flat
left-to-right — they fan on a near/far diagonal, front slot large and
foreground, the other two smaller and staggered behind, "Pokémon-adjacent"
without adopting Pokémon's active/bench *mechanic* (§2.2 is explicit that
this stays purely a staging choice — everyone in the fan is simultaneously
in the fight, nobody is benched). This is a refinement of the adopted
grammar, not a replacement of it.

### 2.1 Backdrops

The isometric diorama grammar **is** adopted for static **encounter
backdrops** — one plate per combat context. `systems/combat.gd` already
enumerates exactly six (`CONTEXT_RAID`, `CONTEXT_MUGGING`,
`CONTEXT_EVENT_MUGGING`, `CONTEXT_HOME_RAID`, `CONTEXT_EVENT_RAID`,
`CONTEXT_DEFEND_VEIN`), and `is_canonical_context()` guarantees the set is
closed.

Six static plates is the cheapest atmosphere-per-asset in the project. A rainy
Shoreditch street corner or a Tube carriage interior does more for perceived
production value than any amount of character animation, and costs one
generation each.

**Flagged (2026-08-29 continuation) — tone/lighting is not fixed per
context.** Backdrop mood depends on the encounter's actual in-game location
and time-of-day, not on which `CONTEXT_*` value is active. This may mean the
eventual asset count is plates-per-location×time rather than one static plate
per context as scoped above; needs its own scoping pass before backdrop
production starts. The daylight-mundane mood locked in §1 is confirmed for
one location/time combination (`CONTEXT_MUGGING`), not asserted as universal
across all six contexts.

### 2.2 Squad roster and stage composition

**New decision (2026-08-29).** Combat moves from "one enemy entity per fight"
(a raid's `"3× Mugger"` counted as a single stat block, per the original §3
sprite-budget doctrine) to **up to 3 distinct, individually-tracked
combatants per side** — up to 3 enemies, each with their own identity/HP/
intent, and up to 3 allies (player + up to 2 recruited combat-eligible
contacts, `Contacts.can_join_combat()`). This is a real mechanic change, not
just a rendering change — see §2.3.

- **Staging:** each side's up-to-3 combatants render in the diagonal fan
  described in §2 — front slot large/foreground, the other two smaller and
  staggered back. All three are always visible and always "in the fight"
  simultaneously; there is no active/bench swap.
- **Targeting:** whichever combatant is currently focused in the turn-order
  strip (§2.4) is the target for the player's next action. Swiping the strip
  and picking a target are the same gesture — there is no separate
  tap-to-target step. AoE items (Black Hole, per §5) ignore focus and hit
  everyone on the affected side, as today.
- **Target callout:** the currently-targeted fanned sprite gets a thin
  outline/glow (shader, not new art) so the stage agrees with the strip at a
  glance, without full resize/refocus staging.
- **Art cost:** effectively zero beyond what §3 already budgets. Squad combat
  reuses the same one-sprite-per-template roster — multiple concurrent
  instances of the same template (e.g. two Muggers) are just two placements
  of the same sheet at different fan positions, same as the old mob-count
  compositing already did.
- **Roster content gap, flagged:** today only Archie is combat-eligible
  (`Contacts.can_join_combat()`), so the ally fan's back two slots are empty
  until a milestone adds a 2nd/3rd recruitable combat contact. The fan
  geometry is built for 3 now so that content doesn't force a second layout
  pass later (§13 open questions has the milestone-placement question).

### 2.3 Scope change flagged — squad combat + turn-based resolution

**Resolved 2026-08-30 — see `docs/REFERENCE.md` §3.7a.** Both mechanic
changes below are now specified: squad state (`combat.enemies` array,
`focusedEnemyIndex`), turn-order queue (speed-sorted, no separate initiative
roll), and the new `combatSkill` player stat (attack bonus + turn speed,
trained via combat + a new HQ Train action). `docs/VISION.md`'s M5 line is
amended accordingly (§12). The two items below are kept as a record of what
was flagged; §3.7a is now canonical for both.

Two mechanic changes surfaced in the 2026-08-29 session that this document
requires but is **not authorised to specify** (per its own scope-of-authority
line) — both need dedicated `REFERENCE.md` work, and both push
`VISION.md`'s M4 "squad combat" line earlier than currently scheduled:

1. **Squad combat itself** (§2.2) — distinct multi-enemy state, per-enemy
   intent, targeting rules, and how AoE/status effects apply across a real
   roster instead of a single resolved enemy. `VISION.md` currently schedules
   this at M4 ("2–3 enemies, per-enemy intent rows, AoE targeting"); this
   session pulls it earlier. Needs its own scoping/milestone conversation
   before implementation — this document only fixes what the *UI* looks like
   once it exists.
2. **Turn-based resolution**, replacing the current simultaneous-resolution
   combat loop. Today `player_attack()` (`systems/combat.gd:298`) resolves
   the whole round synchronously — player, then `_allies_act()`, then the
   enemy — in one call, with no concept of individual turn order. A turn
   queue (who's next, how initiative is decided, how frozen/motion-turn
   status effects reorder the queue, how multi-enemy AI decides who acts
   when) is now a hard prerequisite, not just the beat-queue-for-animation
   work §8 already calls out. **Not designed in this session** — the UI only
   commits to reserving space for a turn-order indicator (§2.4) and to that
   indicator reflowing (animated, reusing the §8 tween-director pattern)
   when the queue changes.

Neither of these is optional once §2.2/§2.4 ship — they're prerequisites, the
same way §8's beat queue already is for the original single-enemy plan.

### 2.4 Turn-order strip — nameplates, targeting, and detail in one component

**New decision (2026-08-29).** Rather than three separate UI elements
(per-sprite nameplate tags, a swipeable per-side detail card, and a
turn-order queue indicator), all three jobs are **one component**: a single
horizontal carousel strip across the top of the 390×360 stage window,
ordered by current turn order (interleaving both sides — whoever's state
computes as "next" appears next in the strip, regardless of which side
they're on).

- **This replaces on-stage nameplate overlays entirely.** The stage itself
  shows only the fanned pixel-art sprites plus the §2.2 target-outline glow
  — no floating enamel signs over the diorama. One source of truth for
  name/HP/status, not two.
- **Swiping the strip** changes focus, which (§2.2) is simultaneously
  "who am I inspecting" and "who am I about to hit."
- **Card states, collapsed vs. focused:**
  - *Collapsed* (every card except the currently-focused one): name, a
    small level badge, faction-colour border, and an HP bar — length only,
    no number. Fast to scan across up to 6 simultaneous combatants.
  - *Focused* (the centred/selected card): adds the exact HP number, status
    effects (frozen, shielded, motion-turns), and for enemies, the
    telegraphed intent/ability (§4.2) — this is where that work now lives,
    rather than a separate enemy-only UI element.
- **Reflow:** when turn order changes mid-fight (a frozen combatant's slot
  moves, a Motion-boosted extra turn inserts, etc.), the strip animates the
  reorder rather than snapping — same tween-director technique §8 already
  specifies for the beat queue, not a second animation system.
- **Nameplate anatomy** (street-sign reference, both collapsed and focused
  cards share this structure):
  - Top, bold black-on-white: combatant name.
  - Top-right, small accent numeral: level.
  - **The dividing rule line doubles as the HP bar** — faction-coloured,
    depletes by *length*, not hue (faction colour stays constant at every
    HP level; see below for why colour is spoken for). Below ~20% HP, the
    bar/card pulses (shader/tween, no art) as a separate urgency cue,
    independent of the length signal.
  - Bottom, coloured text: faction name in the faction's colour, or
    "UNKNOWN" in dark grey when the context doesn't reveal it (below).
  - **Damage-decal tiers, cheap and shared:** a generic overlay decal set
    (crack lines, a chipped corner, rust speckle — authored once against the
    master palette, §6) composites over *any* nameplate at increasing
    intensity as its owner's HP drops: clean above ~60%, cracked 30–60%,
    ruined below 30% (with a slight tilt/hang-askew transform at the ruined
    tier). Zero per-combatant art cost — one decal set serves every card.
- **Faction-colour mapping** (border + bottom text + HP-bar colour), reusing
  `data/factions.json`'s existing `colour` field (already used by the Map
  tab, `systems/map_style.gd`) — **not** a new in-combat stealth roll:
  | Context | Colour shown |
  |---|---|
  | `CONTEXT_DEFEND_VEIN`, `CONTEXT_HOME_RAID` (someone raids you) | Always dark grey/unknown — structural, matching the already-shipped `raid-stealth-anonymity` decision that these fights always use a generic guard-template enemy, never naming the faction, regardless of any stealth roll. |
  | `CONTEXT_RAID` (you raid a faction's vein) | The target faction's real `colour` — you chose the vein, so you already know whose it is. |
  | `CONTEXT_MUGGING`, `CONTEXT_EVENT_MUGGING` | Always dark grey — muggers have no faction affiliation at all (`generate_mugger()`), not a concealed one. |

### 2.5 Command deck — action cards and the Dial widget

**New decision (2026-08-29).** Below the 390×360 stage window, the command
deck holds three regions:

- **Action deck — 3 cards, not 4.** Attack / Item / Run, matching the
  existing `_build_action_bar()` action set exactly (`scenes/screens/
  combat.gd:90`). These are a visual re-skin of the current three buttons as
  cards, not a new inventory/hand mechanic — no energy-cost numbers, no
  fixed draw of items. "Item" still opens the existing Bag drawer.
- **The Dial — not a card.** A distinct rotating handle widget (the
  umbrella-handle prop), separate from the action deck, because it's a
  different interaction: **rotate** (drag/swipe around the handle) cycles
  through the Dial's currently-*loaded* complications only (`dial.gd`'s
  `loadedComplications` — unloaded capacity isn't selectable mid-combat);
  **trigger** (a press on the handle/knob) casts whichever complication is
  currently selected. **Charge remaining** renders as an analog clock-face
  built into the top of the handle (not pips or a linear meter) — it's the
  resource that gates whether a trigger-press does anything, so it must be
  visible without opening a menu. If zero complications are loaded, the
  widget doesn't render (nothing to select).
- **Art style (locked 2026-08-29 continuation, via image-gen test): pixel
  art, a deliberate one-off exception.** The Dial is diegetic (a physical
  prop the player holds), unlike the action cards and log, which stay
  vector/parchment-theme chrome. This amends §9: pixel art is not
  stage-only — the rule is diegetic props render in pixel art, abstract UI
  controls stay vector.
- **Physical design, locked:** a thick handle (diameter close to the dial
  cap's own width, not a thin rod under a wider disc) with the dial built
  into its top as continuous material, not a separate attached head.
  Rendered from an elevated three-quarter angle, not flat-on, so the
  cylindrical body and the dial face read together. The rotating bezel
  needs its own distinct texture/material band, raised notches, and a fixed
  pointer marker, or it doesn't read as a part that turns; hands and tick
  marks are bold and simple, not fine detail, so they survive being scaled
  down to real UI size. Umbrella fabric/ferrule detailing is not needed —
  the handle-with-built-in-dial reads clearly on its own. Note:
  `dial.gd`'s `loadedComplications`/`capacityMax` is not a fixed slot count
  (it varies by dial level and per-complication `capacityCost`) — the art
  must not imply a fixed number of bezel notches.
- **Layout: Dial docked right, full height.** The Dial widget is a vertical
  strip on the right edge of the command deck, spanning the full height of
  the action-card row *and* the departure-board log below it — evoking
  holding the umbrella handle in the off-hand while the cards are dealt in
  front of you. Right side chosen for right-hand-thumb ergonomics (most
  players) and because it reads as the "finishing move," swiped to after the
  mundane action-deck choices.
- **Speed toggle + player stats** sit in their own row at the bottom of the
  command deck, full width beneath the Dial strip's span (as in the original
  rough mockup).

## 3. The cast and its frame budget

| Subject | Source | Sheets |
|---|---|---|
| Player | `state.player` | idle, attack, hit, KO, item-use |
| Archie | `data/constants.json` → `contacts.archie` | idle, attack, hit, KO, self-patch (`_allies_act` heals below 40% HP) |
| Territorial Scrapper | `data/enemies.json` | idle, attack, hit, KO, tell |
| Vein Guard | `data/enemies.json` | idle, attack, hit, KO, tell |
| Orichalchum Dealer | `data/enemies.json` | idle, attack, hit, KO, tell |
| The Raider | `data/enemies.json` | idle, attack, hit, KO, tell |
| Mugger | `generate_mugger()` | idle, attack, hit, KO — one sprite, mirrored/offset for the 2× and 3× cases |

**Superseded by §2.2/§2.3 (2026-08-29):** "do not draw multi-enemy groups" no
longer holds as written — squad combat means up to 3 *distinct* enemies can
be on stage at once, each independently tracked. What's unchanged is the
**art cost**: no new sprites are needed for this. Multiple concurrent
enemies are multiple placements of the same one-sprite-per-template roster
above (fanned per §2.2), the same way the old mob-count compositing already
placed one Mugger sprite at staggered depths for `"3× Mugger"`. The frame
budget below is unaffected; what changes is the *state layer* (§2.3), which
this document doesn't specify.

Ally roster is similarly generic, not Archie-specific: `Contacts.
can_join_combat()` already allows any recruited contact with a combat kit,
so the frame budget per ally-template applies to whichever contacts end up
combat-eligible, not just Archie. Only Archie exists today (§2.2's flagged
content gap).

## 4. Animation doctrine — three keyposes, transforms, effects

The load-bearing insight about the reference games: **their character
animation is minimal.** A Bravely Default attack is a lunge, a pose swap and a
return. The spectacle comes from the effect layer, the hit-stop and the camera.

This is doubly correct here, because image models cannot hold a character's
identity across eight hand-drawn frames. The doctrine is not a compromise
forced by the tool — it is the technique the reference games already use.

| Beat | Generated frames | Motion source |
|---|---|---|
| Idle | 2–3, ping-pong, ~6fps | generated |
| Attack | 3 keyposes (wind-up / strike / recover) | **transform** lunge and return between poses |
| Hit | 1 pose | transform recoil + white flash (shader, not art) |
| KO | 2 poses | transform fall + fade |
| Ability tell | 1 pose, held | pulse |

≈9–10 frames per subject × 7 subjects ≈ **70 frames for the entire roster.**

Budget saved on characters is spent on **effect sheets**, which is where the
spectacle actually lives and which generate far more reliably — they sit on
transparent ground and have no identity to preserve.

### 4.1 The juice layer

Style-independent, and the highest feel-per-line in the whole plan:

- Hit-stop, 60–90ms on a landed hit
- Damage numbers rising and fading from the struck combatant
- Screen shake, 3–6px, scaled to damage as a fraction of `hpMax`
- HP bar lag drain — a ghost bar chasing the real one
- Flash-to-white on the struck sprite

### 4.2 Enemy telegraph

The state layer already carries `ability`, `evadeChance` and
`lockedTurns` per enemy (`_enemy_capabilities_from_template`,
`systems/combat.gd:67`). Surfacing the wind-up pose before the enemy acts is
the single biggest **design** gain available here — Slay the Spire's intent
icon, in sprite form. It converts a fight from a dice roll into a decision,
and it is what finally makes `prophetsBreath` legible.

## 5. Effect vocabulary

One signature visual verb per item. No two alike — the point is that a player
can identify what was used from the corner of their eye.

| Item | Effect |
|---|---|
| `timePearl` | Frost ring; enemy desaturates via shader; all enemy tweens drop to ~10% speed |
| `enhancementPowder` | Afterimage trail (no art — duplicate sprite on an alpha ramp) plus 2–3 rapid lunges, matching the 2×/3× attack count |
| `blast` | Shockwave ring, ~6 frames. On disarm, the weapon sprite spins out of frame |
| `shield` | Shimmer plane, 4-frame loop; cracks and sheds a layer on each absorb |
| `blackHole` | Inward warp, ~8 frames. The one expensive effect; worth it |
| `healingBurst` | Rising motes, ~5 frames, HP bar refills with an overshoot bounce |
| `prophetsBreath` | The enemy's *next* pose ghosts in at ~30% alpha before it happens |
| `wormhole` | Player folds to a vertical line and vanishes; the parting-shot beat never plays |
| `rewind` / `failsafe` | The whole stage plays backward — free, it is the beat queue in reverse |

## 6. Asset pipeline

The reference images are three different palettes — warm tungsten interior,
cold blue rain, neutral character plate. Left alone they will read as a mood
board rather than one game. Pipeline discipline, in order:

1. **Reference palette.** 32–48 colours, committed as `data/palette.json`
   plus a swatch PNG, for the mood direction and for shared named-colour uses
   (e.g. `combat_visuals.json` backdrop `fallbackColor`). Generated assets
   are **not** quantised to it.
2. **Re-gridify.** Generated pixel art is rarely on a true pixel grid and
   carries anti-aliased fringe. Build `tools/pixelize.py`: detect native cell
   size → downsample nearest → strip fringe → trim to a fixed canvas. Run it
   on everything, no exceptions.
3. **Never re-prompt a character.** Generate one canonical sprite per subject,
   then produce every other pose by editing *that image*, or generate all
   keyposes as a **single strip in one generation**. Re-prompting per frame is
   how you get a character whose face changes mid-punch.
4. **Manifest, not hardcoding.** `data/combat_visuals.json` maps enemy
   template key → sheet path + animation names; the screen reads it. Keeps the
   constitution's DATA-first rule intact and means a new enemy template needs
   no code.
5. **`docs/ART-BIBLE.md`** holding palette, canvas sizes, the lighting rule
   (all three references are top-left key light — keep it) and the generation
   prompt template, so the art is reproducible in six months.

### 6.1 Canvas sizes

Native, at the 390×844 logical viewport:

| Asset | Native size |
|---|---|
| Combatant | ~64 × 104 |
| Backdrop plate | 390 × 360 |
| Effect frame | 96 × 96 |
| Large effect (`blackHole`) | 160 × 160 |

## 7. Render settings — three gotchas

1. **`textures/vram_compression/import_etc2_astc=true` (`project.godot:38`)**
   applies to textures imported in VRAM-Compressed mode. Block compression on
   pixel art produces visible artifacts — every combat sprite must import
   **Lossless**, mipmaps off, filter off. Set it as the folder default so it
   cannot be flipped by accident.
2. **Set `rendering/textures/canvas_textures/default_texture_filter` to
   Nearest.** The default is Linear and will turn the art to mud.
   `gl_compatibility` (the project's renderer on both desktop and mobile) is
   otherwise fine for this.
3. **Pick one snapping rule and never mix it.** 1 art pixel = 1 logical pixel
   ≈ 3 device pixels on a modern phone under `canvas_items` stretch, which is
   crisp — but tweened positions land on fractions and shimmer. Either enable
   `rendering/2d/snap/snap_2d_transforms_to_pixel` (crunchy, authentic) or
   allow subpixel throughout (smooth, slightly soft). Mixing the two across
   characters and effects is what makes indie pixel games look broken.

## 8. Architecture — the beat queue is a prerequisite

Nothing above is reachable without this, and it is more load-bearing with
sprites than it was with cards, because sprites must survive across turns.

Two blockers in the current code:

- **`player_attack()` (`systems/combat.gd:298`) resolves the whole round
  synchronously** — player attacks (1–3 of them under motion), then
  `_allies_act()`, then the enemy attack, appending every log line and
  emitting one `state_changed` at the end. There is no per-beat timeline to
  animate against.
- **`CombatScreen._refresh()` (`scenes/screens/combat.gd:14`) `queue_free()`s
  every child on each `state_changed`.** No sprite, tween or animation player
  can live through that.

The fix, respecting the one-way data flow:

1. Systems return an ordered `beats` array alongside the log lines —
   `{kind: "player_attack", dmg: 7, target: "enemy"}`,
   `{kind: "enemy_evade"}`, `{kind: "ally_heal", amount: 12}`. Pure data, so
   `GameState.state` stays a pure tree and Rewind keeps working. **No
   `SpriteFrames`, Node or Callable ever enters state** — ids only; the screen
   resolves them through `data/combat_visuals.json`.
2. The screen holds **persistent** combatant nodes and stops rebuilding them.
3. A director plays the beat queue with a duration knob, tap-to-fast-forward
   and skip.

`scenes/components/map_canvas.gd` is already exactly this pattern — tween-driven
one-shot visual classes, `pacing_mode`, `custom_step()` fast-forward, a
persisted player-facing pacing toggle. **Copy that architecture; do not invent
a second one.**

## 9. Framing — resolving the collision with the chrome

`theme/main_theme.tres` is cream parchment and amber. The pixel stage's art
direction (§1) is a different rendering technique entirely — pixel grid,
dithered shading, muted daylight palette. Dropping one into the other reads
as a bug.

**The lit-window frame.** The pixel stage sits in a recessed dark inset with a
hard 2px border and a slight inner vignette, embedded in the existing chrome —
so it reads as a window onto the street, not a style clash. This is Octopath's
own trick (vignette isolating the diorama), and it is the composition of the
Tube-carriage reference plate.

**Exception, locked 2026-08-29 continuation:** the Dial (§2.5) is pixel art
too, despite sitting in the command-deck chrome below the stage window, not
inside it — because it is a diegetic prop (something the player physically
holds), not an abstract control like the action cards or log. The rule is:
diegetic props render in pixel art wherever they sit; abstract UI controls
stay vector/parchment chrome. This is the one exception; it does not extend
to the rest of the command deck.

Do **not** re-theme the rest of the app's chrome to match the stage's palette
on the back of this work. The seam is deliberate and it is the subject of
§11.

## 10. Ticket order

1. `docs/ART-BIBLE.md` + master palette + `tools/pixelize.py` — **before any
   asset generation**
2. Beat queue director + persistent combatant nodes — no art; cards still, to
   prove the plumbing separately from the aesthetics
3. Stage frame, backdrop plates (6), render/import settings (§7)
4. Seven idle sheets
5. Attack / hit / KO keyposes, transform motion, juice layer (§4.1)
6. Effect sheets per consumable (§5)
7. Enemy telegraph (§4.2)

Steps 1–3 are the ones that are expensive to retrofit. Everything from 4 on is
incremental and can ship in any order.

## 11. The wider opportunity — flagged, not settled

**Every screen except the Map tab is placeholder aesthetics**, and the Map tab
itself is acknowledged to need substantial work. `scenes/components/ui.gd` is
a functional widget kit, not a designed one; `theme/main_theme.tres` is a
default-ish parchment theme.

That makes this the cheapest moment the project will ever have to set
**project-wide** standards, because there is almost nothing to retrofit. The
combat work will produce, as a side effect, the first real answers to
questions every future UI ticket needs:

- the master palette (§6.1) — currently no screen has one
- the pixel grid and snapping rule (§7) — binding on any future pixel asset
  anywhere in the app
- the lighting rule
- typography — presently the engine fallback font everywhere, which
  `scenes/components/ore_glyphs.gd` already documents as unable to render the
  five ore symbols, forcing hand-drawn vector glyphs
- what the chrome around a pixel stage looks like (§9)

**Live exception: the Map tab.** Its target is a London Underground diagram —
a deliberate, different visual language, and correct for what it does. Whether
it eventually becomes a *pixel-art* Underground diagram is an open question
(§13), not a decision this document makes.

**Recommendation:** promote §6/§7 out to `docs/ART-BIBLE.md` as project-wide
standards as soon as they are proven in combat, rather than authoring them a
second time later. This document deliberately does not attempt the full art
bible.

## 12. Amendments required to docs/VISION.md

Per the constitution's conflict rule, the ticket that lands the first pixel
asset must also land these:

| Line | Current text | Problem |
|---|---|---|
| `docs/VISION.md:103` | "One illustration + icon set = **the entire exploration art budget**." | Directly contradicted. The art budget now includes a sprite roster, six backdrop plates and an effect library. |
| `docs/VISION.md:103` | "one stylised hand-drawn map — an occult A-Z, ink on paper" | Survives *only* as the Map tab's own direction, and is itself under review (§13). Must be scoped to the Map tab rather than stated as the game's art direction. |
| `docs/VISION.md:12` | "a stylish, text-forward, menu-driven interface layered over a hand-drawn map of London" | "text-forward, menu-driven" still holds. "hand-drawn" does not. |

VISION.md is agreed to be outdated in places; these three are the ones this
work actually invalidates, and no more.

**New, from the 2026-08-29 pass:** `VISION.md`'s M4 line ("**squad combat**
(2–3 enemies, per-enemy intent rows, AoE targeting for Black Hole and mass
Pan's Prank) with T4 enemy content") is now scheduled earlier than M4 by
this document's §2.2/§2.3 — needs its own milestone-planning conversation
(not settled here) to decide where the *mechanic* actually lands, distinct
from the UI work this document specifies.

## 13. Open questions

1. **Map tab.** Underground-diagram direction is confirmed. Pixel-art
   Underground diagram, or vector? Affects whether the palette in §6 is
   genuinely project-wide.
2. **Reference plates.** The three direction references are not committed —
   this repo is public and they are AI-generated working material. Commit to
   `docs/art-refs/`, or keep them in `.scratch/` alongside the private ticket
   breakdowns? Two locked test renders (backdrop mood, Dial style) now exist
   from the 2026-08-29 continuation session, pending the same commit
   decision.
3. **Milestone placement.** `docs/VISION.md` schedules a juice pass (tweens,
   particles, haptics, sfx) in M6. Does this work land there, or earlier as
   its own line?
4. **Font.** Pixel art will make the engine fallback font look wrong. A
   bundled pixel font is probably implied by this direction but is not costed
   here.
5. ~~**Turn-order/initiative mechanic**~~ — **resolved 2026-08-30**, see
   `REFERENCE.md` §3.7a: a new `combatSkill` player stat drives speed (and
   attack bonus), allies/enemies carry an authored flat speed, queue is
   speed-sorted each round with a fixed tie-break.
6. ~~**Squad-combat mechanic itself**~~ — **resolved 2026-08-30**, see
   `REFERENCE.md` §3.7a: `combat.enemies` array + `focusedEnemyIndex`
   targeting, per-enemy independent AI targeting, AoE hits all non-koed
   enemies undiluted, roster spawning with per-instance stat variance.
7. **2nd/3rd combat-eligible ally content** — the ally fan is built for 3
   (§2.2) but only Archie exists today; which milestone adds the next
   recruitable combat contact is unscheduled.

## 14. Continuation — aesthetic theme and art style

**2026-08-29, second continuation session — resolved:**
- Palette/brightness direction locked (§1): overcast daylight, muted,
  mundane — not noir.
- Backdrop plate mood for `CONTEXT_MUGGING` locked (§1, §2.1).
- Dial widget art style locked: pixel art, a diegetic one-off exception to
  the vector command-deck chrome (§2.5, §9).
- Dial's physical design corrected (§2.5) from the original description.

**Flagged, not decided:**
- Backdrop tone/lighting across the other five contexts depends on in-game
  location and time-of-day, not a fixed per-context rule — may mean §2.1's
  "one plate per context" framing needs revisiting (§2.1).
- A full-screen composite sanity check (stage + turn-order strip + command
  deck together) has not been generated.
- Typography (§13 item 4) — not addressed.

These continue in a further session.

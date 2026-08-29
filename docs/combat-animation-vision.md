# Combat Animation & Art Direction — Vision

**Status:** Draft from a design session (2026-08-26). Written against
`collective1`. Combat-scoped by decision; §11 flags the wider art-direction
opportunity but does not attempt to settle it.

**Scope of authority:** this document is canonical for **combat presentation**
— battle grammar, sprite budget, animation technique, asset pipeline and the
render settings pixel art requires. It does not define mechanics; every number
in combat still lives in `docs/REFERENCE.md` §3.7 and `data/enemies.json`.

Where it conflicts with `docs/VISION.md` on art direction, **this document
wins** and VISION.md must be amended in the same ticket that lands the first
pixel asset (§12), per the project constitution.

**Prose:** contains no player-facing copy. Nothing here is `PROSE-REVIEW:`
material.

---

## 1. The decision

Combat moves to **full sprite-frame pixel art** — visible player, allies and
enemies, idle loops, and per-action animation. This supersedes the previous
plan of record.


The reference direction is high-fidelity modern indie pixel art: dense detail,
practical light sources, contemporary London subject
matter. Nearest tonal cousins: **Backbone**, **NORCO**, **The Last Night**,
**Eastward**.

## 2. Battle grammar — the portrait problem

Bravely Default, Octopath Traveler, Sea of Stars, Cassette Beasts and Chained Echoes all use a
**horizontal battle line**. The viewport is **390×844 portrait**
(`project.godot`), so that grammar is unavailable and must not be half-copied.

| Grammar | Reads as | Precedent | Verdict |
|---|---|---|---|
| **Stacked bands** | Enemy band in the upper third facing down-camera; player + ally band lower, three-quarter back-turned. Depth comes from scale and backdrop perspective, not screen width. | **Octopath Traveler: Champions of the Continent** — Octopath's own art solving this exact problem in portrait mobile. Fire Emblem Heroes. | **Adopt** |
| Enemy-only front view | Camera *is* the player. Cheapest, most portrait-native. | Dragon Quest, Etrian Odyssey | Rejected — loses the player representation this work exists to add |
| Isometric diorama | Combatants placed in a receding scene. | Into the Breach, Final Fantasy Tactics, Fell Seal | Rejected for combat: iso needs multiple facings per sprite, 3–4× cost |

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

**Do not draw multi-enemy groups.** `generate_raid_enemy()` renders counts as
`"%d× %s"` against a single stat block. Compose the group on screen from one
sprite at staggered depths; the state layer has one enemy and the art must not
pretend otherwise.

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

1. **Lock a master palette.** 32–48 colours, committed as `data/palette.json`
   plus a swatch PNG. Quantise **every** generated asset to it. This single
   step is what makes generated pixel art read as one authored game.
2. **Re-gridify.** Generated pixel art is rarely on a true pixel grid and
   carries anti-aliased fringe. Build `tools/pixelize.py`: detect native cell
   size → downsample nearest → quantise to palette → strip fringe → trim to a
   fixed canvas. Run it on everything, no exceptions.
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

`theme/main_theme.tres` is cream parchment and amber. The art direction is
dark and noir. Dropping one into the other reads as a bug.

**The lit-window frame.** The pixel stage sits in a recessed dark inset with a
hard 2px border and a slight inner vignette, embedded in the existing chrome —
so it reads as a window onto the street, not a style clash. This is Octopath's
own trick (vignette isolating the diorama), and it is the composition of the
Tube-carriage reference plate.

Do **not** re-theme the rest of the app to noir on the back of this work. The
seam is deliberate and it is the subject of §11.

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

## 13. Open questions

1. **Map tab.** Underground-diagram direction is confirmed. Pixel-art
   Underground diagram, or vector? Affects whether the palette in §6 is
   genuinely project-wide.
2. **Reference plates.** The three direction references are not committed —
   this repo is public and they are AI-generated working material. Commit to
   `docs/art-refs/`, or keep them in `.scratch/` alongside the private ticket
   breakdowns?
3. **Milestone placement.** `docs/VISION.md` schedules a juice pass (tweens,
   particles, haptics, sfx) in M6. Does this work land there, or earlier as
   its own line?
4. **Font.** Pixel art will make the engine fallback font look wrong. A
   bundled pixel font is probably implied by this direction but is not costed
   here.

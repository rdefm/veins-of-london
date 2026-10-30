# Combat item effects + status icons — design proposal

**Status:** open questions resolved (2026-10-28, §7). No tickets cut yet.
**Builds on:** `docs/combat-animation-vision.md` §4–§5 (effect vocabulary, juice layer), the Time Pearl freeze (`combat-lab-profile-polish` 06–08) and the Rewind VHS overlay.
**Mechanics source:** `docs/REFERENCE.md` §3.7b (Items, Table 4, Move levels). Nothing below changes a rule; every animation hangs off a beat kind or a combatant field that already exists.

---

## 1. Design principles

1. **One verb per item.** A player should name the item from the corner of their eye, with the transcript hidden. No two items share a silhouette *and* a colour.
2. **Ore family = colour family (agreed as the default rule).** Every item is made of one or two ores; its effect palette comes from those, so the stage teaches the crafting system for free. Exceptions are allowed, but each one needs human approval. Any proposed exception is flagged as **EXCEPTION** where it appears.

   | Ore | Effect palette (proposal) | Items |
   |---|---|---|
   | time | pale cyan / cold white, tape-grain | Time Pearl, Prophet's Breath, Rewind |
   | physics | sodium orange / hot white, hard edges | Blast, Shield, Black Hole |
   | life | warm green / gold motes | Enhancement Powder |
   | fate | clover green / brass glint | Be a Lady |
   | emotion | magenta / rose / bruise-purple | Panic, Pan's Rapture, Panger, Pandemonium |
   | time+life | cyan→gold blend | Healing Burst, Failsafe |
   | time+physics | cyan→orange blend | Wormhole |

3. **Four-phase anatomy, cheapest-first.** Every item is *launch → travel → land → linger*. Launch reuses the existing `throw`/`cast` pose. Travel is a tween (no art). Land is the one effect sheet (96×96, §6.1). Linger is a shader or overlay, never a looping sheet unless it's the item's whole identity (Shield already is).
4. **The tone is dry, the effects aren't.** Danger stays sincere (vision §1 tone note). Effects can be vivid; they never wink — no cartoon stars, no "POW".
5. **Already-shipped rules carry over:** quick pacing halves every duration; Rewind plays beats backward under the VHS overlay with restored frames rebuilding linger states directly (no in/out transitions — same as freeze 08); KO clears every linger instantly; hold-to-peek and tap-target keep working through every effect.
6. **Reduced motion** (Settings): drop shake, camera punch and full-stage tints; keep the land frame and the status icon. Information never lives *only* in motion.
7. **All numbers in `data/combat_visuals.json`** — one block per item under `effects` (sheet, fps, durations, tints) and a new `statusIcons` block.

---

## 2. What exists today (the hooks)

- `combat_rounds.gd` `beat_cues()` maps beat kinds → stage calls: `attack`, `afterimage`, `throw`, `cast`, `vanish`, `recoil`, `effect`, `damage`, `shieldCrack`, `ko`, `overlay`.
- `_ITEM_EFFECTS` maps 7 beat kinds → 5 effect sheets (`timePearl`, `blast`, `shield`, `healingBurst`, `blackHole`). **All five `image` paths in `combat_visuals.json` are empty** — they play nothing yet.
- `panic`, `rapture`, `anger`, `fury` play a bare `throw`. `powder`, `sight`, `sightGiven`, `lady`, `failsafe` play a bare `cast`. `cower`, `enraptured`, `calm`, `disarm` are overlay-only (no animation at all). `retaliate`, `pull` play nothing.
- Status display: `StageSlot` draws a guard marker (cyan/white corner glyph), **text** status badges in amber 9px (`Panic (2)`, `Anger +50%`, `Disarmed (2)`), the ⏸N pause icon, the shield crack flash. The strip carries `guardBadge` + `statusBadge` text lines.

So the plumbing is done; what's missing is sheets, linger shaders, the Dial-cast variant and an icon language.

---

## 3. Item-by-item

Format: **Launch / Travel / Land / Linger / Exit**. "Sheet" = new effect-sheet art. Cost: 🟢 tween/shader only · 🟡 one small sheet · 🔴 large or multi-sheet.

### 3.1 Blast ☄ (physics) — 🟡
- **Launch:** `throw`, arm snaps forward harder than a Strike (shorter wind-up, 1px overshoot).
- **Travel:** a single orange pixel spark arcs to the target, 120ms, 2-frame trail.
- **Land:** 6-frame shockwave ring (already budgeted) + hard white flash on the target + 2-frame hit-stop + screen shake at the *crit* scale (it ignores guard — it should feel like it). Guard marker on the target **flickers** once to show it was ignored, not broken.
- **Disarm (15%, `disarm` beat):** the target's weapon is shown as a tiny generic pixel shape (knife/cosh silhouette, one shared sprite) spinning up and out of frame, 400ms, rotating 720°. Lands nowhere. Then the Disarmed icon pops in (§4).
- **Flee boost:** a faint orange chevron settles on the *actor's* feet — see the "Legs" status icon (§4). On the actor's next Leg it, the chevron streaks behind them.
- **Multi:** one spark per target, staggered 60ms left→right; one shared shake.

### 3.2 Shield ⛨ (physics) — 🟡 (sheet exists in budget)
- **Launch:** `throw` at own feet (`shield`) or toward an ally (`shieldOther`).
- **Land:** a hex-panel plane assembles bottom-up across the sprite in 4 frames (panels "snap" on with a click-rate of 1 panel/frame).
- **Linger:** the existing 4-frame shimmer loop. **Proposal:** loop opacity scales with pool remaining — full shimmer at full pool, sparse flickering panels near empty, so the player reads "nearly broken" without a number.
- **Absorb (`absorbed` > 0):** keep `flash_shield_crack`, add 1–2 panels falling off and fading downward (tween on a cropped region of the land sheet, no new art).
- **Break (pool → 0):** remaining panels burst outward in 4 directions, 200ms, then the guard marker resolves to the combatant's real guard state (often Open — which is the important tactical news).
- **Enemy Shield:** same effect, palette-swapped toward grey-steel so the player instantly knows whose it is.

### 3.3 Black Hole ⊙ (physics) — 🔴 (the one expensive effect, per vision §5)
- **Launch:** `throw` overhand, high arc.
- **Travel:** a black bead with an orange rim lifts to the enemy band's centre, hangs 150ms.
- **Land:** 8-frame inward warp (160×160) centred between the enemies. During it: backdrop gets a radial pinch shader (UV pull toward centre, 6–10% strength), every enemy sprite leans 8–12° toward the centre and stretches 10% on the lean axis, hit-flash on each, damage numbers spawn *at the singularity* and fly outward to each target.
- **Linger:** each affected enemy loses actions — reuse the "Lost" treatment from Stun (§4 Stunned icon), not the freeze shader. Black Hole and Time Pearl must not look alike: Pearl = paused tape, Black Hole = crushed and dazed.
- **Exit:** snap back with a 1-frame outward pop and small shake.

### 3.4 Time Pearl ⧖ (time) — shipped
- Shader + tape-stop + ⏸N done. **Only gap:** the 4-frame `timePearl` land sheet is still empty. Proposal: a pale frost-ring/tape-reel ripple that expands once from the pearl's landing point, *before* the tape-stop, so there's a cause before the effect.

### 3.5 Healing Burst ✚ (time+life) — 🟡
- **Launch:** `throw` to an ally or `cast` on self (`healSelf`) — a cupped-hands variant of cast if the pose sheet ever grows one; otherwise cast.
- **Land:** 5 gold-and-cyan motes rise from the feet, 5 frames (budgeted). A soft gold rim-light shader pulse on the sprite (one sine, 300ms).
- **Numbers:** green `+N` rising number (reuse damage-number spawner with a colour + sign param). HP bar on the strip refills with the overshoot bounce from vision §5.
- **Fizzle (KO'd target):** motes rise and then fall/scatter grey. Communicates "wasted" without text.

### 3.6 Enhancement Powder ↯ (life) — 🟢/🟡
- **Launch:** `cast` — the actor snorts/slaps on the powder: 3-frame puff of green-gold dust at head height (small sheet, 48×48 is enough).
- **Land:** the sprite's idle speeds up to ~1.6× for the effect's life, and one afterimage peels off immediately (`spawn_afterimage`).
- **Linger:** a faint 2-ghost afterimage trail on every *movement* (attack lunge, throw) while `powderUntil` holds. Idle stays clean so the stage isn't noisy.
- **The extra action itself:** when the bonus action's strip card comes up, the card enters with a green "+1" corner tab (strip side, no stage art).
- **Exit:** idle speed eases back over 300ms; tiny dust puff.

### 3.7 Prophet's Breath ≋ (time) — 🟢
Sight is a *player-information* effect, so it lives mostly in the UI layer, not on a sprite.
- **Launch:** `cast` — the actor exhales a pale cyan ribbon that drifts across the stage toward the enemy band (tween a 1-px-wide line with sine wobble; no sheet).
- **Land:** each enemy whose intents just became read gets a quick 2px cyan outline sweep (top → bottom, 200ms). On the strip, every `?` card flips like a departure-board flap to its real intent, staggered 40ms per card. **This flip is the payoff** — it's the thing the player paid for.
- **`sightGiven` (an ally gives it to the player):** ribbon goes ally → player first, then out to the enemies.
- **Linger:** "Sight" status icon on the player (§4). No sprite shader.
- **Carry-in (fight starts under sight):** the flip runs once at the end of the intro deal-in.

### 3.8 Be a Lady ☘ (fate) — 🟢
- **Launch:** `cast` — actor straightens; a brass glint travels up the sprite (thin diagonal highlight sweep shader, 250ms).
- **Linger:** every Strike the actor lands while `ladyUntil` holds gets a single-frame clover-green glint on impact, and the damage number renders in brass rather than white (it's always a max roll — show that it is).
- **Crit under Lady:** a slightly larger glint + 40ms extra hit-stop.
- **Evade cut:** when an enemy would have evaded but the cut made it land, no special cue — invisible maths stays invisible.

### 3.9 Panic ☹ (emotion) — 🟡
- **Launch:** `throw` — a small magenta vial shatters on the target (reuse the Blast travel spark, recoloured).
- **Land:** a 4-frame rose-pink "flinch" ring + the target recoils (`play_hit` without the white flash).
- **Linger:** jitter shader (1px random offset at ~12Hz, sprite-only, not overlay) + slightly desaturated. Panic icon with count (§4).
- **`cower` turn:** sprite squashes down 15% and holds for the beat; small "shudder".
- **`bolt` turn:** plays the shared **run-off exit** (below). It's a KO for the fight, so the slot empties with no fall pose.

**Run-off exit (agreed; shared by Panic `bolt` and a successful Leg it `fled`):** sprite flips to face away (`mirror`), takes a 1-frame crouch, then slides off the nearest screen edge fast (300ms, ease-in) leaving 2 afterimages and a small dust kick at the start point. A Leg it boosted by Blast adds the orange streak at the feet (§3.1). Rewinding plays it backward (the sprite runs back in). It replaces `vanish` for both beats; `vanish` (fold to a line) stays Wormhole-only, so running away and folding out of space never look alike.

### 3.10 Pan's Rapture ☺ (emotion) — 🟡
- **Launch:** `throw`, vial bursts into a slow rose-gold shimmer.
- **Land:** a 4-frame soft bloom; sprite's idle drops to half speed.
- **Linger:** slow sway (±2° rotation on a 1.5s sine around the feet) + warm pink tint at ~25%. Rapture icon with count.
- **`enraptured` (idle turn):** sway pauses at peak lean for the beat, a single pink motes puff rises.
- Reads as the *opposite* of Panic: Panic is fast and small, Rapture slow and wide.

### 3.11 Panger ☠ (emotion) — 🟢
- **Launch:** `throw` — red spark.
- **Land:** sprite flashes deep red twice (modulate, not white flash).
- **Linger, two phases, tracking `anger_factor()`:**
  - *Hot phase (deals +X%, takes −X%):* red pulsing rim (sine 1Hz), sprite scale +4%.
  - *Cold phase (deals −X%, takes +X%):* rim goes bruise-purple, scale −4%, slight slump (y +1px).
  The phase change plays a quick flip of rim colour with a 1-frame squash — the player needs to see the switch because it flips who should be hitting whom.
- **`calm` beat:** rim fades out over 300ms, scale eases home.

### 3.12 Pandemonium ♨ (emotion) — 🟡
- As Panger, plus **fury**: a 3-frame looping heat-shimmer/steam wisp above the head (small sheet, 32×32) while `fury` is true.
- **Friendly-fire strike:** the attacking enemy's lunge targets its ally; a magenta line flashes between them for 2 frames before the swing so the player's eye follows a wrong-way attack.

### 3.13 Wormhole ⊗ (time+physics) — 🟢 (exists as `vanish`)
- Keep `play_wormhole_vanish` (fold to a line). Add: a 1-frame cyan-orange lens tear at the point of vanish, and a camera hold of 300ms on the empty slot before the outcome card. It stays distinct from the run-off exit (§3.9) used by `bolt` and Leg it: those run away, Wormhole folds.

### 3.14 Failsafe ⚑ (time+life) — 🟢
- **Hidden until it fires (agreed):** no icon or cue while it's equipped.
- Fires on a lethal hit. Sequence: the killing hit lands, freeze-frame 200ms, the player's sprite turns to a white silhouette, then a **short, fast** local rewind (VHS overlay at 2× rewindSpeed, cropped to a vignette around the player only, ~400ms) to the restored snapshot. A small flag icon (⚑) pops above the player and falls away to show the unit was spent.
- Ally Failsafe (keeps ally on 1 hp): same silhouette beat, no rewind — the sprite staggers, the flag pops, HP bar lands on a hair.
- Guard-kit rewind (ally spends a `rewind` on the player's behalf): the full-stage VHS overlay as normal Rewind, but the ally's sprite briefly glows cyan first so the player sees who saved them.

### 3.15 Rewind ⟲ — shipped. No change.

### 3.16 Dial casts (any Complication) — 🟢
**Agreed for now:** a Dial cast plays exactly like the thrown item (same `throw` launch). The human will later add a sprite of the character aiming and firing the Dial, and that pose replaces `throw` for Dial casts. The rest of this section is parked until then:
- Player: the Dial widget in the dock does a quarter-twist + its screw for that Complication flashes; a thin brass tracer runs from the dock up into the stage to the actor's hand; actor plays `cast` (not `throw` — nothing is thrown). ~250ms extra.
- Ally Dial casts: actor `cast` + brass ring flash at the hand.
- Magnitude (Dial level): scale the land effect 1.0 / 1.1 / 1.2 at L1/L3/L5 — cheap, legible "this one's stronger".

### 3.17 Multi-target units
One launch, one travel that **splits** into N paths mid-flight (fan of sparks), land effects staggered 60ms in array order, one shared shake. The split is the "multi" tell.

### 3.18 Enemy item use (raider kit)
Same effects, palette shifted ~20% toward grey-steel so the player can see an enemy Shield/Blast/heal is *theirs* even in a cluttered frame.

---

## 4. Status icons

### 4.1 Scope (agreed)
Icons replace the **on-stage** text badges above the sprites (9px amber `Anger +50%` is unreadable once three are stacked, and in-scene labels should be glyphs, per vision §9). The **strip cards and transcript keep their text**: the text still says exactly what happened, and the icon is the at-a-glance version on the stage.

### 4.2 Icon grammar
- **9×9 px pixel glyphs** (drawn at 1 art pixel = 1 logical pixel, like the ⏸ icon), on a 11×11 chip.
- **Buff vs debuff by chip shape:** buffs on a rounded chip with a light rim; debuffs on a notched/cut-corner chip with a dark rim. Readable in greyscale and for colour-blind players.
- **Colour = ore family** of the cause (§1 table); conditions with no item (Stunned, Feinted) use neutral white.
- **Count pip:** a single pixel-font digit bottom-right of the chip for anything with remaining actions/rounds. Ticks down with a 1-frame flick.
- **Placement:** a row above the head, centred, left→right in a fixed priority order (removal → control → damage mods → buffs). Max 3 visible; a 4th collapses to `+N`. The ⏸N pause icon keeps its existing slot above the row and stays the largest (it's the most important thing on the stage when present).
- **Guard marker stays its own thing** at the corner — it's state, not status, and the most-read glyph in the fight.
- **Strip unchanged:** strip cards keep the `statusBadge` text line; icons are stage-only.
- **Peek:** hold-to-peek lists each status with full text and remaining count ("Panic — 2 actions", "Anger: deals +50% for 1 more, then −50% for 2"). The icon is the hint, the peek is the rulebook.

### 4.3 Animation of icons
- **Apply:** pop from 0 → 120% → 100% scale, 140ms, with a 1-frame white chip flash.
- **Tick:** count digit flicks (1 frame at 2px up), chip nudges 1px.
- **Expire:** chip shrinks to a dot and blinks out, 120ms; for buffs, a tiny 2-pixel sparkle.
- **Rewind/restore:** icons set directly, no pop (matches freeze 08).

### 4.4 The roster

| Status | Source field / beat | Glyph (9×9 idea) | Chip | Colour | Count | Sprite-level treatment (beyond the icon) |
|---|---|---|---|---|---|---|
| **Guarded** | `guard` / shield | existing guard marker | — | cyan | — | existing |
| **Open** | `guard`, `openActions` | existing marker | — | white | — | **New:** when `openActions` (Stun L5 hold-open) > 0, marker gets the count pip |
| **Frozen** | `frozenActions` | ⏸ (shipped) | — | time cyan | ✓ | VCR pause (shipped) |
| **Stunned / Lost** | `actionsLost − frozenActions` | buffering spinner (§4.6 A) | debuff | white | ✓ | head bob: 1px slow circular drift of the sprite top (shear shader), 0.8s loop |
| **Feinted** | `guardFailed` | a broken shield outline | debuff | white | — | none — the icon *is* the tell. On the failed Guard beat: guard marker tries to raise, cracks, falls |
| **Feint bonus** | feinter's +X% on the target (until it re-guards) | crosshair | debuff | white | — | — (shows "+20%" in peek) |
| **Shielded** | `shield` > 0 | — (the shimmer is the status) | — | physics | — | existing loop, opacity scales with pool (§3.2) |
| **Powdered** | `powderUntil` | ↯ / double chevron | buff | life green | rounds | movement afterimages (§3.6) |
| **Sight** | `sightUntil` (player) | open eye | buff | time cyan | rounds | none on sprite; enemies' read intents already show it |
| **Lady** | `ladyUntil` | ☘ | buff | fate | rounds | impact glints (§3.8) |
| **Panic** | `panicActions` | ☹ | debuff | emotion magenta | ✓ | jitter (§3.9) |
| **Rapture** | `raptureActions` | ☺ | debuff | emotion rose | ✓ | sway + tint (§3.10) |
| **Anger (hot)** | `angerActions`, factor ≥ 1 | ☠ with up-arrow | debuff* | emotion red | ✓ | red rim pulse |
| **Anger (cold)** | factor < 1 | ☠ with down-arrow | debuff | bruise purple | ✓ | purple rim, slump |
| **Fury** | `fury` | ♨ | debuff | emotion red | ✓ | steam wisp (§3.12) |
| **Disarmed** | `disarmed`, `ability.lockedTurns` | empty hand / crossed blade | debuff | physics orange | rounds (if locked) | — |
| **Leg-it boost** | `fleeBoost` > 0 | running chevron | buff | physics orange | — | faint chevron at feet |

Failsafe gets no status icon: it stays hidden until it fires (§3.14).

\*Anger is a debuff applied to an enemy even in its hot phase (it's two-edged); keep the debuff chip, let the arrow carry the direction.

### 4.5 Data shape (suggestion)
`combat_rounds.gd` `status_badges()` returns strings, which the strip keeps using. Add a sibling `status_icons()` returning `[{ id, count }]` (pure data, ids as above) for `stage_marks()`. The stage resolves `combat_visuals.json` `statusIcons[id] = { glyph, chip, colour }`. Same one-way flow, no Nodes in state.

### 4.6 Stunned glyph: modern options (pick one)
Today's London, not Victorian. Every option is a 9×9 loop of 2–4 frames orbiting or hovering just above the head:

| Option | Reads as | Tone risk |
|---|---|---|
| **A. Buffering spinner** — the 8-dot loading wheel, one dot lit and chasing | "not responding" | Low. Dry and universally read. **My pick** |
| **B. No-signal bars** — phone signal bars dropping to one, then blinking | "lost connection" | Low; slightly abstract at 9px |
| **C. Orbiting pigeon feathers** — 2–3 grey feathers circling | London-specific, mildly absurd | Medium; closest to a cartoon gag |
| **D. Tinnitus squiggle** — a thin high-frequency wavy line ringing round the head | the ringing after a hit | Low; the most sincere, but the least instantly legible |
| **E. Dead-pixel static** — a small patch of flickering TV-snow | "signal lost", picks up the VHS/tape motif from Rewind and Pearl | Medium. Could blur into the time effects' look, so it may need an **EXCEPTION** to the ore-colour rule

---

## 5. Move beats that currently play nothing

Not items, but they share the stage and are cheap wins while this work is open:

| Beat | Today | Proposal |
|---|---|---|
| `block` (Guard L3/L5 zero-damage) | attack pose only | a bright cyan "tink" spark at the contact point, `0` damage number in cyan, guard marker pulses |
| `autoguard` | afterimage | afterimage + the guard marker *slides* in from the side (it wasn't there, then it was) |
| `retaliate` | nothing | defender's attack pose with a 1-frame white outline flash first — "this one's free" |
| `stunThrough` | attack pose | a crack-through-guard spark: the guard marker shatters 2 frames, then the Stunned icon pops |
| `fizzle` (Stun on Guarded) | attack pose | the attacker's swing glances off: grey spark, small backward recoil on the *attacker* |
| `evade` | attack pose | defender sidesteps 6px and back (tween), afterimage left at the original position |
| `fled` (Leg it success) | vanish | the run-off exit (§3.9) |
| `fleeFailed` | recoil | stumble: sprite trips forward 4px, rotates −8°, recovers |
| `levelUp` | transcript only | brass `L↑` pip rises from the sprite, small sparkle |
| `enter` (reinforcement) | overlay only | sprite slides in from the band's off-screen edge, 250ms |

---

## 6. Priority + cost

| Order | Item / work | Why first | Art cost |
|---|---|---|---|
| 1 | Status icon system (§4) + `status_badges()` data shape | Fixes a readability problem on every fight; unblocks linger visuals | ~16 9×9 glyphs + 2 chip shapes |
| 2 | Shield, Blast, Healing Burst land sheets | Most-used items; sheets already budgeted and wired, images empty | 3 small sheets |
| 3 | Stun / Lost treatment + Black Hole | Removal is the core tactic; Black Hole must not borrow Pearl's look | 1 large sheet + shaders |
| 4 | Pan family (Panic, Rapture, Panger, Pandemonium) | Status-heavy, most to gain from icons + sprite shaders | 2 small sheets + shaders |
| 5 | Powder, Prophet's Breath, Lady | Mostly shader/UI work, low art | 1 tiny sheet |
| 6 | Failsafe, Dial-cast launch, multi split, enemy palette | Polish on top of the above | none |
| 7 | §5 move-beat fills | Cheap, independent | none |

Total new sheet art: ~7 sheets (1 large), plus the icon set. Everything else is shader/tween/overlay on existing nodes.

---

## 7. Decisions + open questions

**Decided (2026-10-28):**
- Ore-colour language is the default; each exception needs human approval (§1.2).
- Icons sit above the stage sprites only. The strip and transcript keep their text (§4.1).
- Panic `bolt` and a successful Leg it share a new run-off exit; `vanish` stays Wormhole-only (§3.9).
- Failsafe stays hidden until it fires (§3.14).

- Stunned glyph: option A, the buffering spinner (§4.6).
- Dial casts play like a thrown item for now (§3.16). An aim-and-fire Dial sprite comes later from the human.
- Glyphs: mocked up for now (code-drawn or placeholder pixels). The human will swap in custom pixel art later, so glyphs must load from paths in `combat_visuals.json` `statusIcons`, with the mock as the fallback.

**Open:** none.

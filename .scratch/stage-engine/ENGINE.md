# Stage engine — how it works and how to change it

Live pixel-art scenes for events, replacing static card art in the event screen's VN image slot.
Prototype content: `archie_craft_chat` (Spitalfields Market + Archie). Ticket: `issues/01-stage-engine-archie-craft-chat.md`.

## Why native Godot, not video

- Godot's native video is Ogg Theora; codec compression smears pixel edges and bleeds colour.
- Video costs ~1–5 MB per scene vs ~20–50 KB of PNGs, seams at every card cut, can't branch on choices or vary with state, and burns battery decoding.
- Native: crisp integer scaling, continuous idle animation across cards, rigs/sets reused across events, Rewind-safe, reduced-motion aware, headless-testable.
- Art is still made **outside** the engine (Python generator now, Aseprite/artist later) and played back in Godot — the standard split.

## File map

| Path | Role |
|---|---|
| `scenes/stage/stage_player.gd` | `StagePlayer` (Control). Builds SubViewport world, fits it to the slot, runs card steps, effects, camera, ambient life. One shared clock (`advance(delta)`). |
| `scenes/stage/stage_actor.gd` | `StageActor` (Node2D). Layered rig sprites, attributes, blink/chew/talk/breathe/tilt, rig actions, anchors. Stepped by the player, not by `_process`. |
| `scenes/stage/slow_field.gdshader` | Slow-field look: tinted dome on the floor, rippling what's behind it by whole pixels (`hint_screen_texture`); `motion` 0 = static tint. |
| `scenes/stage/stage_direction.gd` | `StageDirection` — pure static logic: fold card steps into snapshots, drop landing, talk length, viewport fit. No nodes, no GameState writes. |
| `data/stages/<event_id>.json` | **Hand-authored** direction for one event (set, actors, camera, one `steps` list per event card). Its existence turns the stage on. |
| `data/stages/rigs/<rig>.json` | **Generated** rig manifest (parts, frames, anchors, defaults, actions, behaviour timings). |
| `data/stages/sets/<set>.json` | **Generated** set manifest (layers, walkers, ambient sprites, lights, objects, props). |
| `assets/stages/rigs/<rig>/*.png`, `assets/stages/sets/<set>/*.png` | Generated art. |
| `tools/stage_art/` | Generator: `raster.py`, `rig_archie.py`, `set_spitalfields.py`, `build_stage_assets.py`, `preview_rig.py`, `preview_set.py`; character kit `char_kit.py` + `characters.py`; intro mock-up `set_alley.py` + `build_intro_stage.py`. |
| `autoload/GameData.gd` | `_load_stages()` scans `data/stages/` into `STAGES` / `STAGE_RIGS` / `STAGE_SETS` (keyed by file basename). |
| `systems/events.gd` | `has_stage()`; `is_vn_mode()` returns true for staged events. |
| `scenes/screens/event.gd` | VN frame adds a `StagePlayer` to the image slot when `Events.has_stage()`; `_refresh_vn_card()` calls `show_card(cardIndex)` on staged cards, `rest()` + card PNG past the stage's last entry. |
| `tests/test_stage.gd` | Data integrity, fold, talk length, viewport fit, VN mode, full card run, reduced motion. |
| `scripts/debug_stage_screenshot.gd` | Windowed (not headless) harness; saves frames to `.scratch/stage-engine/shots/`. |

## Rendering model

- **Design size** `180×240` (set manifest `design_size`); VN slot is ~3:4.
- **Integer scale**: `scale = floor(frame_px.x / 180)`, viewport size = `ceil(frame_px / scale)` → covers the slot exactly with square pixels; visible world width varies slightly per device (≥180).
- `frame_px` = control size × (root final transform × canvas transform) scale, i.e. physical pixels.
- SubViewport: nearest filtering, `snap_2d_transforms/vertices_to_pixel`, 3D off, update always. Shown via a `TextureRect` (nearest, exact size, centred, pixel-aligned).
- **World** is bottom-aligned (`world.y = vp_h - world_h`), so taller slots reveal more roof, never cut feet.
- **Camera** is a single `camera_x`; `camera_left = clamp(camera_x - vp_w/2, 0, world_w - vp_w)`. Each parallax node sits at `x = -round(camera_left * parallax)`.

### Draw order (back → front)

1. `back` layers (far wall, parallax 0.6)
2. walkers (same parallax as far layer)
3. `mid` layers (market + floor, parallax 1.0)
4. near node (parallax 1.0): ambient sprites (vendor) → lights (additive glow) → object backs → actors → props → object fronts → slow fields
5. `front` layers (fore, parallax 1.25)

Floor seam: the far layer owns the floor up to `SEAM_Y` (236) so walkers' feet sit on it; the market layer's floor starts there with a kerb line hiding the parallax seam.

### Layer image coordinates

Layer PNGs are drawn in their **own** parallax space: `screen_x = image_x - camera_left * parallax`. When placing content in a non-1.0 layer, compute where it must be for the camera range you use (fore layer is 440 wide for this reason).

## Direction model (the important part)

A card's look is **derived, never stored**:

- `resolve_start(stage, i)` = defaults folded through every step of cards `0..i-1`.
- `resolve_end(stage, i)` = start of `i` + all of card `i`'s steps.
- `show_card(i)` snaps to `resolve_start(i)`, then schedules card `i`'s steps on the shared clock. Same index twice = no-op (event screen refreshes on every `state_changed`).
- Reduced motion: snap to `resolve_end(i)`, schedule nothing, no ambient/idle motion.

So Rewind, save/resume, fast taps and skipping all render correctly with zero game state. **Keep it that way: never put stage data in `GameState.state`.**

### Snapshot shape

```
{ "camera_x": float,
  "actors":  { "<actor_id>": { "arm_l", "arm_r", "eyes", "brows", "mouth", "tilt",   # rig attrs
                               "facing": "left"|"right", "x": int, "visible": bool } },
  "objects": { "<object_id>": { "x": int } },                         # every set object, centre x
  "props":   [ { "prop": "<prop_id>", "x": float, "y": float } ],   # props resting on the floor
  "fields":  [ { "x": int, "radius": int, "height": int, "scale": float } ] }   # standing slow fields
```

Initial values: actor `x` / `facing` / `hidden` from the stage's `actors` entry (`facing` defaults to the rig's `faces`, `hidden` to false); object `x` from the stage's optional `"objects": {"<id>": {"x"}}` override (e.g. a car parked off-screen), else the set manifest.

### Step kinds (`data/stages/<event_id>.json` → `cards[i].steps[]`, each has `t` seconds)

| Step | Live effect | Lasting effect (fold) |
|---|---|---|
| `"set": {"archie.mouth": "agape", ...}` | sets attributes now | attributes persist |
| `"play": "archie.wave"` | runs a rig action (timed sets) | action's sets applied in order |
| `"talk": "archie"` | mouth flaps for `talk_seconds(card text)`, then returns to base mouth | none |
| `"drop": {"prop", "from": "archie.mouth", "land": [dx, dy]}` | prop falls (gravity), hops, rests | prop rests at actor feet + `land` |
| `"throw": {"prop", "from": "archie.hand_l", "to": "bin", "dur", "arc"}` | parabolic flight into the object's mouth, object wobbles | none (prop is gone) |
| `"throw": {"prop", "from", "at": 120, "dur", "arc"}` | parabolic flight to floor x `at`, shatters into a burst of pixel shards (motion only) | none (prop is gone) |
| `"slow": {"x", "radius", "scale", "height"?, "grow"?}` | slow field (dome on the floor, default height 150) swells over `grow` s; actors whose feet are within `radius` of `x` run their clock at `scale` | field stands for the rest of the event |
| `"camera": {"x", "dur"}` | smoothstep pan | camera stays at `x` |
| `"move": {"target", "x", "dur"}` | actor or set object travels to `x` (smoothstep, integer px); actors with a rig `walk` cycle play it and stand on arrival, others slide | target stays at `round(x)` |
| `"show": "<actor_id>"` / `"hide": "<actor_id>"` | actor appears / leaves instantly | visibility persists |

- Targets are `"<actor_id>.<attr>"`. Attributes: `arm_l`, `arm_r`, `eyes`, `brows`, `mouth` (frame names, or a `mouth_states` key like `chew`), `tilt` (degrees, eased), `facing` (`left`/`right`; mirrors the whole rig, anchors and drop `land` dx included). Position and visibility are not `set` attrs — use `move` / `show` / `hide`.
- `move.target` must name exactly one actor or set object. A new move on the same target replaces one in flight. Object moves carry the object's back/front sprites; throws aim at the object's current position.
- `cards` covers the event's **first N cards** — at most one entry per event card (test enforces `<=`). Empty card = `{ "steps": [] }`.
- **Partial coverage:** on a card past the last entry (`Events.is_staged_card()` false) the event screen calls `StagePlayer.rest()` (hidden, `_process` off, viewport not rendering, steps/fx/props cleared) and shows `Events.current_image_path()` like a normal illustrated VN event. The event stays in VN mode throughout. Stepping back onto a staged card (Rewind, resume, re-entry) calls `show_card(i)`, which wakes the stage and rebuilds from the fold.
- Talk length counts only text inside quotes (`"`, `“`, `”`) × `talk_per_char`, clamped `talk_min..talk_max`. Long lines cap at 6 s — schedule late beats (e.g. card 7's tilt at 4.2 s) inside that window.
- A throw takes exactly one of `to` (set object) or `at` (floor x). A floor throw always shatters; pair it with a `slow` step at the landing time for the vial beat.
- **Slow fields:** each tick `StagePlayer.time_scale_of(actor)` = `StageDirection.time_scale_at(fields, actor x)` (slowest containing field, else 1; a growing field counts its current radius). That scale multiplies the actor's `step()` delta (blink, talk, chew, breathe, walk legs, rig actions) and its in-flight `move` progress — so a slowed walk takes `dur / scale`. It's re-evaluated from position every tick: an actor walking out speeds up. Set objects, camera, ambient and the step schedule are never slowed. Reduced motion: field is a static full-size tint, actors already hold still.
- Anchors: `mouth` follows head tilt; `hand_l` / `hand_r` use the hand point of the current arm frame.

## Rigs

Manifest (`data/stages/rigs/archie.json`, generated):

- Every part frame is a full `96×168` PNG on a shared canvas; `origin` = feet (48,159). Overlays (eyes/brows/mouth) are mostly transparent — cheap and keeps offsets trivial.
- `order` = draw order. `group`: `root` (static: shadow, legs), `body` (bobs 1 px to breathe: torso, arms), `head` (inside body, rotates about `anchors.neck`: head, eyes, brows, mouth). Arms come after head so a bite can cover the face.
- `defaults`, `mouth_states` (`chew` → `chew_a/chew_b` cycle), `talk_frames`, `actions`, `behaviour` (blink interval/length, chew timing, talk step; idle life: breathe period + per-actor jitter, weight-shift sway period/px (body ±1 px x, off while walking), idle head drift angle/interval, tilt spring stiffness/damping (overshoot then settle), talk nod angle/chance and 1 px head dip chance). Each actor randomises its own phases at `setup`, so a group never moves in sync. `turn_len`: a live `facing` set dips the body and flips halfway (snapshots flip at once; `is_mirrored()` is the drawn facing). `effort_dip`: a live arm frame change or `play` sinks the body briefly.
- `px`: canvas pixels per art pixel (kit style `scale`; 1 for the hand-built rig). Breath, sway, dips are whole art pixels so scaled styles don't break their grid.
- Optional `faces` (`"right"` default): the way the art faces as drawn; the other `facing` flips the actor node (`scale.x = -1`).
- Optional `walk`: `{"part": "legs", "frames": ["walk_0", ...], "frame_time": s, "stand": "base"}` — every frame must exist in that part. Cycles while a `move` runs (motion on), shows `stand` otherwise. Rigs without it slide.

Archie frames: arm_l `rest hold eat wave_a wave_b crumple throw_back throw_release`; arm_r `rest phone_up phone_low`; eyes `open down closed wide`; brows `normal up knit quirk`; mouth `closed chew_a chew_b talk_a talk_b agape smirk`. Actions: `wave`, `bite`, `throw`.

Screen sides: `arm_l` = viewer-left (Archie's right hand, holds the wrap); `arm_r` = viewer-right (phone).

Style rigs `archie_{chibi,adventure,retro,minimal,minimal_plus}` (character kit, three-quarter view facing right, so `faces` stays the default) add: arm_l `bag bag_wave_a bag_wave_b` (Tesco bag in hand); arm_r `pocket` (hand behind the hip) `vial flick_back flick` (hand_r anchor = the vial, release point on `flick`); mouth `whistle`; legs `walk_0..3` (declared `walk`). Actions: `bag_wave`, `pocket_draw`, `flick`.

## Sets

Spitalfields (`data/stages/sets/spitalfields.json`, generated): world `360×320`, `floor_y` 300, Archie at x 230, default camera 205, bin at x 72 (camera 150 frames it). Walkers loop across `range` with 4-frame cycles; vendor cycles idle/scoop/look with random holds; lights are glow sprites with additive blend and sine flicker.

Alley (`data/stages/sets/alley_<style>.json`, `set_alley.py` via `build_intro_stage.py <style>`): Mile End Road back alley at night, drawn in a character-kit style (the style's scale, tone ramps and outline, so set and cast share one pixel density; with no outline the wall and bins drop darker so the cast reads by tone). World `360×320`, `floor_y` 300; alley mouth onto the road at x < 40 (walkers cross it in the far layer, `range` −24..64); lamp post, kitchen door and fire-door bulkhead are the lights; steam and a cat are ambient. Object `car` (grey Vauxhall, body + headlight beam, 150×60) is drawn behind the cast — `intro2` (chibi), `intro3` (adventure), `intro4` (retro), `intro5` (minimal) and `intro6` (minimal_plus) park it off-screen (x 430) and drive it to 200; buyers `show` in front of its doors. Buyer rigs `knife_<style>` (arm_r `knife_low`/`knife`, action `knife_draw`), `mate_<style>`, `james_<style>`.

## Art generator (`tools/stage_art/`)

- `raster.py`: draws shapes as **(material, shade)** — `poly` (row-cylinder shading), `capsule` (limbs, normal-lit), `ellipse` (sphere-lit), `stamp` (ASCII pixel stamps for faces), `px` (fixed colours). `render()` quantises shade into each material's palette ramp (optional Bayer dither), darkens edges where listed materials meet (`edge_against`), then adds a 1 px outline from each material's outline colour. Single key light from upper-left.
- `rig_archie.py`: likeness notes, all part/frame geometry, face stamps, arm pose table (`ARM_L` / `ARM_R`: elbow, hand, held prop, prop angle), anchors.
- `set_spitalfields.py`: layers, walkers, vendor, glow, props, bin; constants (`FLOOR_Y`, `SEAM_Y`, `STALL_X`, parallax factors) shared with the manifest.
- `char_kit.py` + `characters.py`: the character kit. A style (chibi/adventure/retro/minimal/minimal_plus: rendering, proportions, face stamps) plus a character config (build, hair, facial hair, glasses, outfit lit colours, held props) → part PNGs + rig manifest. Arm frames are dropped for props a character doesn't carry. `build_style_mockups.py [sheet_dir]` writes the Archie style rigs and review sheets (`styles.png`, `kit_<style>.png`).
- `build_stage_assets.py`: writes PNGs + rig/set manifests. **Edit the generator, never the generated JSON.**
- `preview_rig.py <out.png>` / `preview_set.py <out.png>`: upscaled review sheets (rig poses + face close-ups; composited set at default and pan camera). Use these to iterate visually before touching Godot.

Note: the Windows default encoding is not UTF-8 — open these .py files with `encoding="utf-8"` when scripting edits (they contain `──` comment rules).

## Workflows

**Regenerate art after editing the generator**
```
python tools/stage_art/build_stage_assets.py
godot --headless --import
godot --headless -s tests/test_runner.gd -- test_stage.gd
```
New PNGs need the import pass, otherwise `ResourceLoader.exists()` fails. `*.import` files are gitignored.

**Stage another event with existing rig + set**
1. Create `data/stages/<event_id>.json` with `set`, `camera`, `actors`, and one `steps` list per card.
2. Use only frames and actions that exist in the rig manifest (the test checks every reference).
3. Run `test_stage.gd`, then `godot -s scripts/debug_stage_screenshot.gd [-- <event_id>]` (an event id uses `INTRO_SHOTS`; edit the shot lists as needed) and look at the frames. `-- slow` injects a floor throw + slow field into card 5 (shots in `shots/slow/`).

**Add a pose or expression**
Add an entry to `ARM_L`/`ARM_R`, `EYES`, `BROWS_L`, or `MOUTHS` in `rig_archie.py` (and `build()` / manifest frame lists if it's a new part), then regenerate. New frame names become available to `set` steps straight away.

**Add an action**
Add to `actions` in `rig_manifest()` in `build_stage_assets.py` (timed `set` lists). Its last `set` is what persists in the fold.

**New character rig**
Copy `rig_archie.py` → `rig_<name>.py` with the same canvas/origin convention, add a manifest builder + `write_images`/`write_json` calls in `build_stage_assets.py`. `StageActor` is rig-agnostic as long as the parts use the `root`/`body`/`head` groups and `anchors` include `neck`, `mouth`, `hand_l`, `hand_r`.

**New set**
New `set_<name>.py` + manifest builder. Required manifest keys: `dir`, `design_size`, `world`, `floor_y`, `layers` (with `slot` back/mid/front), `walkers`, `ambient`, `lights`, `objects`, `props` (empty lists/dicts are fine). Each object: `x` (centre), `size`, `back` (drawn behind actors), optional `front` (drawn over actors and props — e.g. a car door someone steps out from behind), `mouth` if it is a throw target.

**New step kind**
Add it in three places: `StageDirection.apply_step_end` (its lasting effect, if any), `StagePlayer._run_step` (live behaviour), and `_step_problems` in `tests/test_stage.gd` (plus a bad example in `validation_catches_bad_cast_steps`). A new lasting effect also needs a snapshot field and `StagePlayer._apply_snapshot` support.

**Replacing generated art with hand-made art**
Keep file names, canvas sizes and origins identical, and anchors in the manifest matching the new drawings. Then stop regenerating that rig/set, or the generator will overwrite it. Once a rig is hand-made, move its manifest out of the generator's ownership (hand-edit it).

## Invariants / gotchas

- Presentation only: stage code reads `GameData` and `meta.reducedMotion`; it never writes state. Don't add Nodes/Callables to `GameState.state`.
- `show_card` must be idempotent for the same index.
- Keep all positions integer (`round()`) — sub-pixel positions shimmer at integer scale.
- `StageActor.step()` is driven by `StagePlayer.advance()`; don't add `_process` to actors (double-stepping).
- In-flight effects and resting props are cleared on every card change and rebuilt from the snapshot.
- `check_runner.gd` / tests run headless (dummy renderer) — they can't see pixels. Visual checks need the windowed screenshot harness or a device.

## Open / possible next steps

- On-device QA (crispness, readability of faces at phone scale, performance/battery).
- Fore planter crosses the middle of the frame during the card 12 pan — may want trimming.
- Audio cues (chew, bin thunk) not implemented.
- Choice cards: steps are per card index; branch-specific direction would need keying by choice result.

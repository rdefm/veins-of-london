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
| `scenes/stage/stage_direction.gd` | `StageDirection` — pure static logic: fold card steps into snapshots, drop landing, talk length, viewport fit. No nodes, no GameState writes. |
| `data/stages/<event_id>.json` | **Hand-authored** direction for one event (set, actors, camera, one `steps` list per event card). Its existence turns the stage on. |
| `data/stages/rigs/<rig>.json` | **Generated** rig manifest (parts, frames, anchors, defaults, actions, behaviour timings). |
| `data/stages/sets/<set>.json` | **Generated** set manifest (layers, walkers, ambient sprites, lights, objects, props). |
| `assets/stages/rigs/<rig>/*.png`, `assets/stages/sets/<set>/*.png` | Generated art. |
| `tools/stage_art/` | Generator: `raster.py`, `rig_archie.py`, `set_spitalfields.py`, `build_stage_assets.py`, `preview_rig.py`, `preview_set.py`. |
| `autoload/GameData.gd` | `_load_stages()` scans `data/stages/` into `STAGES` / `STAGE_RIGS` / `STAGE_SETS` (keyed by file basename). |
| `systems/events.gd` | `has_stage()`; `is_vn_mode()` returns true for staged events. |
| `scenes/screens/event.gd` | VN frame adds a `StagePlayer` to the image slot when `Events.has_stage()`; `_refresh_vn_card()` calls `show_card(cardIndex)` instead of loading a PNG. |
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
4. near node (parallax 1.0): ambient sprites (vendor) → lights (additive glow) → bin back → actors → props → bin front
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
  "actors": { "<actor_id>": { "arm_l", "arm_r", "eyes", "brows", "mouth", "tilt" } },
  "props":  [ { "prop": "<prop_id>", "x": float, "y": float } ] }   # props resting on the floor
```

### Step kinds (`data/stages/<event_id>.json` → `cards[i].steps[]`, each has `t` seconds)

| Step | Live effect | Lasting effect (fold) |
|---|---|---|
| `"set": {"archie.mouth": "agape", ...}` | sets attributes now | attributes persist |
| `"play": "archie.wave"` | runs a rig action (timed sets) | action's sets applied in order |
| `"talk": "archie"` | mouth flaps for `talk_seconds(card text)`, then returns to base mouth | none |
| `"drop": {"prop", "from": "archie.mouth", "land": [dx, dy]}` | prop falls (gravity), hops, rests | prop rests at actor feet + `land` |
| `"throw": {"prop", "from": "archie.hand_l", "to": "bin", "dur", "arc"}` | parabolic flight into the object's mouth, object wobbles | none (prop is gone) |
| `"camera": {"x", "dur"}` | smoothstep pan | camera stays at `x` |

- Targets are `"<actor_id>.<attr>"`. Attributes: `arm_l`, `arm_r`, `eyes`, `brows`, `mouth` (frame names, or a `mouth_states` key like `chew`), `tilt` (degrees, eased).
- `cards` must have exactly one entry per event card (test enforces). Empty card = `{ "steps": [] }`.
- Talk length counts only text inside quotes (`"`, `“`, `”`) × `talk_per_char`, clamped `talk_min..talk_max`. Long lines cap at 6 s — schedule late beats (e.g. card 7's tilt at 4.2 s) inside that window.
- Anchors: `mouth` follows head tilt; `hand_l` / `hand_r` use the hand point of the current arm frame.

## Rigs

Manifest (`data/stages/rigs/archie.json`, generated):

- Every part frame is a full `96×168` PNG on a shared canvas; `origin` = feet (48,159). Overlays (eyes/brows/mouth) are mostly transparent — cheap and keeps offsets trivial.
- `order` = draw order. `group`: `root` (static: shadow, legs), `body` (bobs 1 px to breathe: torso, arms), `head` (inside body, rotates about `anchors.neck`: head, eyes, brows, mouth). Arms come after head so a bite can cover the face.
- `defaults`, `mouth_states` (`chew` → `chew_a/chew_b` cycle), `talk_frames`, `actions`, `behaviour` (blink interval/length, chew timing, talk step, breathe period, tilt speed).

Archie frames: arm_l `rest hold eat wave_a wave_b crumple throw_back throw_release`; arm_r `rest phone_up phone_low`; eyes `open down closed wide`; brows `normal up knit quirk`; mouth `closed chew_a chew_b talk_a talk_b agape smirk`. Actions: `wave`, `bite`, `throw`.

Screen sides: `arm_l` = viewer-left (Archie's right hand, holds the wrap); `arm_r` = viewer-right (phone).

## Sets

Spitalfields (`data/stages/sets/spitalfields.json`, generated): world `360×320`, `floor_y` 300, Archie at x 230, default camera 205, bin at x 72 (camera 150 frames it). Walkers loop across `range` with 4-frame cycles; vendor cycles idle/scoop/look with random holds; lights are glow sprites with additive blend and sine flicker.

## Art generator (`tools/stage_art/`)

- `raster.py`: draws shapes as **(material, shade)** — `poly` (row-cylinder shading), `capsule` (limbs, normal-lit), `ellipse` (sphere-lit), `stamp` (ASCII pixel stamps for faces), `px` (fixed colours). `render()` quantises shade into each material's palette ramp (optional Bayer dither), darkens edges where listed materials meet (`edge_against`), then adds a 1 px outline from each material's outline colour. Single key light from upper-left.
- `rig_archie.py`: likeness notes, all part/frame geometry, face stamps, arm pose table (`ARM_L` / `ARM_R`: elbow, hand, held prop, prop angle), anchors.
- `set_spitalfields.py`: layers, walkers, vendor, glow, props, bin; constants (`FLOOR_Y`, `SEAM_Y`, `STALL_X`, parallax factors) shared with the manifest.
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
3. Run `test_stage.gd`, then `godot -s scripts/debug_stage_screenshot.gd` (edit its `SHOTS` / event id) and look at the frames.

**Add a pose or expression**
Add an entry to `ARM_L`/`ARM_R`, `EYES`, `BROWS_L`, or `MOUTHS` in `rig_archie.py` (and `build()` / manifest frame lists if it's a new part), then regenerate. New frame names become available to `set` steps straight away.

**Add an action**
Add to `actions` in `rig_manifest()` in `build_stage_assets.py` (timed `set` lists). Its last `set` is what persists in the fold.

**New character rig**
Copy `rig_archie.py` → `rig_<name>.py` with the same canvas/origin convention, add a manifest builder + `write_images`/`write_json` calls in `build_stage_assets.py`. `StageActor` is rig-agnostic as long as the parts use the `root`/`body`/`head` groups and `anchors` include `neck`, `mouth`, `hand_l`, `hand_r`.

**New set**
New `set_<name>.py` + manifest builder. Required manifest keys: `dir`, `design_size`, `world`, `floor_y`, `layers` (with `slot` back/mid/front), `walkers`, `ambient`, `lights`, `objects`, `props` (empty lists/dicts are fine).

**New step kind**
Add it in three places: `StageDirection.apply_step_end` (its lasting effect, if any), `StagePlayer._run_step` (live behaviour), and `_assert_step_valid` in `tests/test_stage.gd`.

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

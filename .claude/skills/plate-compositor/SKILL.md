---
name: plate-compositor
description: Run the plate compositor (tools/plate_compositor) over a storyboarded event — set up plate configs, cut characters out of uploaded ChatGPT shot images, compose the cards, QA them and place them as assets/events/... card files. Use when the user says "composite <event>", "run the plate compositor on <event>/<shot>", or says new shot images for a storyboard are uploaded and ready to process.
---

# Plate compositor run

Turns uploaded ChatGPT shot images for an approved storyboard (`.scratch/event-art/<event_id>/board.json`) into placed card art. The tool's how-to is `tools/plate_compositor/README.md` (sections A, C, D); read the section you need before writing a config. Argument: an event id (the board folder name), optionally followed by shot ids (`intro-proposal2 S3`). No shot ids = every shot `status.py` lists under NEXT.

## 1. Status

```
python .claude/skills/plate-compositor/scripts/status.py <event_id>
```

Per shot it shows the plate, linked pose configs, and what's missing: plate config, pose config, cut-out, entry in `shots/<event_id>.json`, placed card (or card older than its inputs). Only shots whose `saveAs` image exists can be processed; the rest say "waiting for AI image". Tell the user which shots you'll process, in one line, then go.

## 2. Plate config (once per board plate)

Missing `tools/plate_compositor/plates/<plate name>.json` → README section D. Specifics:

- `scale`: leave out (default 4). Only set it if the plate visibly uses a different art-pixel size.
- `horizon_y`: native px (full-res ÷ scale). Best source: a standing character's eye line in any shot on that plate.
- `lights` and `occluders`: start from the board plate's `notes` (they list both), positions read off the image in native px. Occluder `depth_y` = where it meets the floor.
- If small saturated props (crates, signs) go grey or brown on the review sheet, add `"quantize": "octree"` and `"plate_colours": 96`.
- A `variantOf` plate (e.g. the same yard plus a car) can start from its parent's config. Keep the parent's lights and occluders that are still visible, then add the new ones. The parent's cut-outs still line up, because the variant is the parent image with additions.

## 3. Cut-outs (`method: "pose"` shots)

README section C, steps 2–4. Per character in the shot image:

- Pose file `poses/<plate>_<character>_<pose>.json`; `ai_image` = the shot's `saveAs`; `out` = `assets/character-references/<Name>/poses/<room>_<pose>.png`. Characters with no reference folder (one-off extras such as the buyers) go in `assets/character-references/extras/poses/`.
- **One pose file per character.** Extraction keeps only the largest connected shape, so separate people need separate regions. Two people overlapping become one cut-out in one region; that's fine.
- `region` is in **full-res px**. Look at the image first, and trace a loose polygon around the character plus anything they touch.
- Run `python tools/plate_compositor/extract.py <pose json> --sheet`, then **look at** `.scratch/plate-compositor/<pose>_extract_sheet.png`. The reported `bbox` touching an edge of the region means background was kept, so tighten the region. Holes, or missing dark clothing against dark walls → `threshold` 35–45, `close` 6–8. Iterate until clean; at most 3 tries per character, then show the user the sheet and ask.
- Small detached marks (♪, speech marks, motion lines) get dropped. That suits the board's no-text rule, so mention it but don't restore them unless asked.
- `reuse` on the board shot names an earlier cut-out: add it to the shot unchanged instead of extracting the character again (the shot prompt told ChatGPT not to draw them).
- If the AI image moved the camera or the room (status says nothing, but `shift` in the extract output is large, or the room visibly differs), stop and tell the user the image needs regenerating.

`method: "sprite"`: README section A (standing sprites by `feet_x`/`feet_y`). `method: "props"`: there's no character; ask the user whether to place the AI image as-is.

## 4. Compose

`tools/plate_compositor/shots/<event_id>.json`, one file per event. Each shot entry has:

- `id`: the stem of the board shot's `file` (e.g. `intro_card6`);
- `board`: the board shot id;
- `label`;
- `plate`: set it when the shot isn't on the file's top-level plate;
- `actors`.

```
python tools/plate_compositor/compose.py tools/plate_compositor/shots/<event_id>.json --only S3 --sheet
```

**Look at** the sheet: feet on the floor, nobody poking through furniture they stand behind, crates and signs keeping their colour, and edges free of leftover wall from the cut-out. Fix and re-run. Cut-outs paste at full res by default, keeping the AI's detail (README section C); don't set `"full_res"` unless the user asks for a grid-snapped one (`false`).

## 5. Place

1. Copy `.scratch/plate-compositor/<id>.png` to the board shot's `file`.
2. Run `godot --headless --import > "$TEMP/imp.log" 2>&1` so `ResourceLoader` sees new files. The `godot_ai`/`preset` errors in that log are pre-existing noise.
3. Check `data/events/<event>.json` (the target event in `file`, not the board id). An explicit `"image"` key on a card overrides the `<event>_card<N>.png` naming convention. If the new card's slot (or a card after it, before the next image) carries an old explicit image, ask the user before removing it.
4. If you changed the event JSON: update `tests/test_events.gd`'s intro image mapping (if it's the intro), patch only that event's entry in `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar`, and run `scripts/run_tests.sh` once.
5. Re-run `status.py`; the processed shots should say DONE.

## Report

Keep it brief: the shots placed, the shots still waiting for images, any pose that needed more than one tuning pass and why, and the extract and compose sheet paths for the user to eyeball. Don't commit unless asked.

# 96 — Storyboard upload: shot drafts ended up in Downloads, not assets/reference-plates/

Status: needs-triage
Type: diagnose + fix

## Report

2026-11-18, board `prologue_archie_sells_pearls`, shot S1 (saveAs `assets/reference-plates/stratford_car_park_S1_archie_on_watch.png`). The user uploaded two new S1 drafts in `tools/storyboard.html` (Shots tab). Neither reached `assets/reference-plates/`. Both turned up in `~/Downloads` instead. The judge found nothing new, and the images had to be copied in by hand as `_v2`/`_v3`.

## Evidence (file times, UTC)

| File in ~/Downloads | Size | Time |
|---|---|---|
| `stratford_car_park_S1_archie_on_watchaa.png` | 2.92 MB | 08:43:56 |
| `stratford_car_park_S1_archie_on_watch.png` | 1.07 MB | 08:44:11 |
| `stratford_car_park_S1_archie_on_watchv2a.png` | 2.71 MB | 09:46:19 |
| `stratford_car_park_S1_archie_on_watchv2.png` | 0.97 MB | 09:46:38 |

- The first round worked: `assets/reference-plates/stratford_car_park_S1_archie_on_watch.png` (1069298 bytes, 08:44) is byte-size identical to the 08:44:11 Downloads file. So that image reached both Downloads and the repo.
- The second round (09:46) reached Downloads only.
- Each round has the same pattern: a ~2.8 MB file, then ~15 s later a ~1 MB file carrying the save-as stem. The suffixes are `v2`, `aa` and `v2a`. These are not the tool's keep-both naming, which is `_vN`.
- `tools/storyboard.html` upload path (`filesBlock` → `send` → `writeFile([...PLATES_DIR, name])`, ~line 7653) has no download fallback. On failure it only sets the status text `Couldn't save: …`. So the tool itself probably did not write to Downloads.

## Hypotheses to test

1. The ~1 MB file comes from another step in the user's flow: a ChatGPT download plus some save/convert step, written to Downloads with a hand-typed name. The 09:46 upload into the tool then failed or never ran. Possible reasons: the folder handle's permission had lapsed after a reload, the backend was server mode with an expired token, the file was dropped outside the `.files` drop box, or a paste failed. The failure was only shown in a small status line that's easy to miss.
2. The browser handled a drop outside the drop box as its default action (open/download the image). The `dragover`/`drop` `preventDefault` is only on the `.files` box, not the window.
3. Something in the current tool really does trigger a download (check for `a.download`, `showSaveFilePicker` and blob URLs in the file and in any served copy).

## Steps

1. Ask the user exactly how they uploaded at 09:46: button, drop or paste; folder mode or server mode; did the tool show `Saved …` or `Couldn't save …`? Also ask what produces the ~1 MB file.
2. Reproduce each upload route in folder mode and server mode, including after a page reload (permission re-prompt) and with a drop just outside the box.
3. Fix what's found. At minimum: block the browser's default drop on the whole window, make a failed save loud (not a one-line status), and re-request folder permission before writing.

## Acceptance

- An upload by any route either lands in `assets/reference-plates/` under the save-as name (`_vN` on keep-both) or shows an unmissable error. It never silently leaves the image elsewhere.
- Dropping an image anywhere on the page never makes the browser open or download it.

## Relevant files

- `tools/storyboard.html`: `filesBlock` (~7641), `folderBackend` (~2306), `serverBackend` (~2353), `detectServer`/`useServer` (~2449–2473), boot (~9302)
- `tools/storyboard_server.js`: server-mode write API
- `.claude/skills/event-storyboard/SKILL.md`: the upload workflow description

## Comments

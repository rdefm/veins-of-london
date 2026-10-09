---
name: event-storyboard
description: Storyboard pixel-art stills for a Vein event (data/events/<id>.json) through a film producer / director / game-UI lens — decide which cards cut to a new shot and which hold, brief each shot, run review rounds on the Vein Storyboards artifact, then coordinate ChatGPT image drafts, QA/cleanup and placement. Use when the user says "storyboard <event>", asks for event card art/images/shots, or hands over drafts for an event already storyboarded.
---

# Event storyboard

Turns one event's cards into an approved shot list, then into placed art. Five phases; never skip an approval gate.

| Phase | Output | Gate to leave it |
|---|---|---|
| 1 Read | event digest + context notes (private) | — |
| 2 Board | board in `.scratch/event-art/<id>/board.json`, seeded to the review page | — |
| 3 Review rounds | revised board, `round` bumped each time; on approval saved + committed | board verdict **approve** and no shot on **revise** |
| 4 Prompts → drafts | `prompts.md`; user's drafts ingested, QA'd, uploaded to the page | board verdict **approve** in phase `drafts` |
| 5 Place | files under `assets/events/<id>/` | user explicitly asks to place |

Workspace: `.scratch/event-art/<event_id>/` holding `board.json` (canonical), `prompts.md`, `drafts/` (user drops ChatGPT output here), `qa/` (script output). `drafts/` and `qa/` are gitignored.

Review page: **https://claude.ai/artifact/9M8iYmgcD1wiZmtttJVwNt** (source `review/storyboard-review.html`; republish with that `url` if the page changes). It reads `boards/<eventId>` and writes the user's verdicts to `feedback/<eventId>__<shotId|board>`. Use the `ArtifactData` tool (load via ToolSearch) to write boards and read feedback.

## Phase 1 — Read

1. `PYTHONIOENCODING=utf-8 python .claude/skills/event-storyboard/scripts/event_digest.py <id>` — every card one-based, choice results, current art per card, staged range, cast + reference sheets.
2. **Staged events:** cards a live stage directs (`data/stages/<id>.json`, first N cards) get cut `STAGED` and no shot. Storyboard only the cards after it.
3. Context, grepped not read whole: who triggers this event and what comes next (`grep -rn "<id>" data/ systems/ --include=*.json --include=*.gd`), the art of the neighbouring events in the chain (`assets/events/<neighbour>/` — look at them; shared locations must match), `docs/CONTENT-GUIDE.md` tone pillars, `docs/ui-vision.md` §2 mood, `docs/ART-BIBLE.md` §1.
4. **Look at** every cast member's reference PNG (`assets/character-references/<Name>/`). Cast without a reference is a canon question for the board, not something to invent silently. Being *mentioned* (e.g. "asks after Hakim") does not put someone on screen.

## Phase 2 — Board

Apply the three lenses in `reference/lenses.md` (producer, director, game-UI). Read it every time; it holds the cut rules, shot grammar and frame constraints.

Images are made with the plate compositor (`tools/plate_compositor/README.md`): one blank **plate** per camera setup, generated once with no people in it, then characters and props added per shot. So plan plates before shots:
- A **plate** = one location seen from one fixed camera. Every shot that keeps that camera reuses it; a new camera position or lens is a new plate. Prefer staging a location's shots on as few plates as the story allows (size changes come from how near the camera an actor stands, not a new camera).
- A lasting change to the set (a car parks, a door is boarded) is a **variant plate**: an edit of its parent plate, with its own name.
- The plate is described in full **once**, in its own prompt. Shots name the plate and describe only who/what is added and how.
- Every prompt is copy-paste ready for ChatGPT and names every attachment by exact file name (`Archie_biz_sprite_master.png`, `mile_end_yard_blank_plate.png`). Prefer the character's `*_biz_sprite_master.png` (the sprite the compositor uses) as their reference. Props with existing game art use that art (crafted items: the recipe icon in `data/recipes.json`, e.g. `assets/combat/icons/timePearl.png`). Grep for existing art before describing a prop from scratch.

Then write `board.json` per `reference/board-schema.md` and seed it:

`ArtifactData set` → url above, collection `boards`, doc_id `<eventId>`, data = the board (`round: 1`, `phase: "storyboard"`, `updatedAt` = epoch ms).

In the terminal, give the user only: the link, one line per plate (`P1 mile_end_yard · from the shop door toward the yard mouth · S1–S5`), one line per shot (`S1 cards 1-2 · P1 · Nadia waiting on the Clerkenwell corner`), the open questions, and your strongest recommendation where you pushed back on the obvious reading. Don't paste the whole board.

## Phase 3 — Review rounds

When the user says they've reviewed: `ArtifactData query` collection `feedback` where `eventId == <id>`. For each shot: `approve` → freeze it; `revise` → apply the note; `cut` → remove the shot and re-HOLD its cards (check that the held image still agrees with each card's text — if not, say so). Notes override your lenses; if a note would break the frame rules (e.g. key detail behind the text panel) say so once, then do what they chose. Answer any question a note asks in the terminal.

Bump `round`, keep frozen shots byte-identical, re-seed. The page shows the latest verdict per shot, so tell the user which verdicts are now stale. Loop until the board verdict is `approve` and no shot is `revise`. Approval authorises **drafts only** — not final assets, not JSON edits.

The page doesn't notify this session; the user says "reviewed"/"approved" and you read the feedback then. **On approval, save it** (the page store overwrites each round, so the repo is the record):
1. Drop shots the user cut; set `board.json` `approved: {round, at: <ISO date>, phase: "storyboard"}`; write it.
2. Write the feedback docs you just read to `.scratch/event-art/<id>/feedback.json` (array, as read, minus `version`).
3. Re-seed the board so the page shows the approved state.
4. Commit `.scratch/event-art/<id>/` with message `Event art: <id> storyboard approved (round N)`, following the repo's commit rules. The user's approval is the go-ahead for this commit.

Draft approval in Phase 4 saves the same way (`approved.phase: "drafts"`, message `… drafts approved`), with `prompts.md` included.

## Phase 4 — Prompts, then drafts

Build `prompts.md` per `reference/prompt-pack.md`: the approved plate and shot prompts from the board, in generation order (plates first, parents before variants). Every generated image (plates and shot drafts) lives in `assets/reference-plates/`, where the compositor reads it: plates as `<plate>_blank_plate.png`, shots as their `saveAs`.

**Uploads.** The user uploads each image on the review page (Upload button on its plate/shot card). The page stores it in the artifact's asset store and lists it in `uploads/<eventId>__<target>` as `{files: [{assetId, name, synced, overwrite}]}`. If the name already exists (in the repo or uploaded), the page asks the user to overwrite or keep both (`_v2`, `_v3`…). When the user says "synced"/"uploaded", or before any draft review:
1. `ArtifactData query` collection `uploads` where `eventId == <id>`.
2. For each file with `synced: false`: `Artifact read` with the page `url`, `path` = `assetId`, `out_dir` = the scratchpad; then move it to `assets/reference-plates/<name>`. Replace an existing file only when the entry has `overwrite: true`. Otherwise a name clash means stop and ask.
3. Set `synced: true` on those entries (`ArtifactData update`, pinned to the version you read).
4. `python .claude/skills/event-storyboard/scripts/present_files.py <id>` refreshes the board's `present` map (what's already on disk), then re-seed the board so the page shows it. An approved plate gets its `tools/plate_compositor/plates/<plate>.json` (README §D) before any shot on it is composed; posed shots go through `extract.py` then `compose.py` (README §C, §A).

After syncing, per new draft:
1. `python .claude/skills/event-storyboard/scripts/pixelize.py <draft> .scratch/event-art/<id>/qa [--scale 4]` and **look at** the `_qa.png` sheet (source | cleaned with crop outlines | small / baseline / tall phone crops).
2. QA against the brief: story accuracy at the frozen instant, character identity vs. reference, set continuity vs. sibling shots and neighbouring events, focal point survives the small-phone crop, nothing story-critical in the bottom ~10%, no legible text/logos, no player face (unless decided otherwise), pixel-grid quality. One line each, pass/fail.
3. The raw upload already shows on the page. Only a derived image you made (a `_clean.png`, a composite) needs uploading: Artifact publish with `url` + `asset: true` + `file_paths`, then append `{url, label}` to the shot's `drafts` (label e.g. `v2 clean 64c`). Set board `phase: "drafts"`, bump `round`, re-seed.

`revise` on a draft → write a *delta* prompt (what to change, "keep everything else identical") for the same ChatGPT conversation rather than a fresh prompt. Never re-prompt a character from scratch once a shot of them is approved — attach the approved draft instead (ART-BIBLE §4).

Pixel cleanup is **optional** until the user says otherwise: offer raw and clean side by side, let them pick per event (`--scale` 4 suits 1024×1536 output; try 3/5/6 if the grid looks wrong; `--palette data/palette.json` snaps to the reference palette, `--no-quantize` keeps colours).

## Phase 5 — Place (only on explicit ask)

1. Copy each approved composite from `.scratch/plate-compositor/` (or raw/clean draft, as chosen) to `assets/events/<id>/<id>_card<n>.png`, where `n` = the shot's first card. Discovery handles HOLD; no JSON edit needed. Explicit `image` keys in the event JSON beat discovery — check with the digest that none shadow a new file. Choice-result shots need an explicit `image` on that choice: that IS a JSON edit, so ask first.
2. `godot --headless --import` (generates `.import` files), then `scripts/run_tests.sh` once.
3. Set board `phase: "done"`; report the placed files plus one short on-device checklist (each new card on a small and a tall phone; holds read correctly; choice/resolution images).
4. Commit per the repo's rules only when asked.

## Don'ts

- Don't edit event prose, cards, or mechanics while storyboarding. A visual problem caused by the text (e.g. a line that describes something no single frame can hold) goes on the board as a question.
- Don't invent lore, faction iconography, or new canon for a character. Ask.
- Don't add `image` keys to event JSON to "help" — discovery is the contract (ADR 0005).

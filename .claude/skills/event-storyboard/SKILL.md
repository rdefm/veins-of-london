---
name: event-storyboard
description: Storyboard pixel-art stills for a Vein event (data/events/<id>.json) through a film producer / director / game-UI lens — decide which cards cut to a new shot and which hold, brief each shot, run review rounds in the local storyboard tool (tools/storyboard.html), then coordinate ChatGPT image drafts, QA/cleanup and placement. Use when the user says "storyboard <event>", asks for event card art/images/shots, or hands over drafts for an event already storyboarded.
---

# Event storyboard

Turns one event's cards into an approved shot list, then into placed art. Five phases; never skip an approval gate.

| Phase | Output | Gate to leave it |
|---|---|---|
| 1 Read | event digest + context notes (private) | — |
| 2 Board | board in `.scratch/event-art/<id>/board.json` (the tool reads it from there) | — |
| 3 Review rounds | revised board, `round` bumped each time; on approval saved + committed | board verdict **approve** and no shot on **revise** |
| 4 Prompts → drafts | `prompts.md`; user's drafts (saved by the tool into `assets/reference-plates/`) QA'd | board verdict **approve** in phase `drafts` |
| 5 Place | files under `assets/events/<id>/` | user explicitly asks to place |

Workspace: `.scratch/event-art/<event_id>/` holding `board.json` (canonical), `feedback.json` (the user's verdicts), `prompts.md`, `qa/` (script output, gitignored).

Review tool: **`tools/storyboard.html`**. The user opens it in desktop Chrome/Edge and picks the repo folder (File System Access API, like `tools/quest-editor.html`). It lists every `.scratch/event-art/*/board.json`, reloads when its window regains focus, writes verdicts to that board's `feedback.json` (array of `{eventId, round, phase, target, verdict, note, at}`, one per target), and saves uploaded images straight into `assets/reference-plates/` under each plate's/shot's save-as name, asking overwrite or keep-both (`_vN`) on a clash. Writing `board.json` is all it takes to publish a board; there is nothing to seed or sync.

(`review/storyboard-review.html` is the older claude.ai artifact version of the same page, at https://claude.ai/artifact/9M8iYmgcD1wiZmtttJVwNt. Use it only if the user asks to review from a phone; its uploads don't work in the mobile app.)

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

Then write `board.json` per `reference/board-schema.md` (`round: 1`, `phase: "storyboard"`, `updatedAt` = epoch ms).

In the terminal, give the user only: "open `tools/storyboard.html`, pick `<id>`", one line per plate (`P1 mile_end_yard · from the shop door toward the yard mouth · S1–S5`), one line per shot (`S1 cards 1-2 · P1 · Nadia waiting on the Clerkenwell corner`), the open questions, and your strongest recommendation where you pushed back on the obvious reading. Don't paste the whole board.

## Phase 3 — Review rounds

When the user says they've reviewed: read `.scratch/event-art/<id>/feedback.json`. For each shot: `approve` → freeze it; `revise` → apply the note; `cut` → remove the shot and re-HOLD its cards (check that the held image still agrees with each card's text — if not, say so). Notes override your lenses; if a note would break the frame rules (e.g. key detail behind the text panel) say so once, then do what they chose. Answer any question a note asks in the terminal.

Bump `round`, keep frozen shots byte-identical, rewrite `board.json`. The tool shows the latest verdict per shot, so tell the user which verdicts are now stale. Loop until the board verdict is `approve` and no shot is `revise`. Approval authorises **drafts only** — not final assets, not JSON edits.

The tool doesn't notify this session; the user says "reviewed"/"approved" and you read the feedback then. `feedback.json` keeps only the latest verdict per target, so commits are the history. **On approval, save it**:
1. Drop shots the user cut; set `board.json` `approved: {round, at: <ISO date>, phase: "storyboard"}`; write it.
2. Commit `.scratch/event-art/<id>/` with message `Event art: <id> storyboard approved (round N)`, following the repo's commit rules. The user's approval is the go-ahead for this commit.

Draft approval in Phase 4 saves the same way (`approved.phase: "drafts"`, message `… drafts approved`), with `prompts.md` included.

## Phase 4 — Prompts, then drafts

Build `prompts.md` per `reference/prompt-pack.md`: the approved plate and shot prompts from the board, in generation order (plates first, parents before variants). Every generated image (plates and shot drafts) lives in `assets/reference-plates/`, where the compositor reads it: plates as `<plate>_blank_plate.png`, shots as their `saveAs`.

**Uploads.** The user saves each image with the tool's Upload button (or drag-drop/paste) on its plate or shot card, which writes it straight into `assets/reference-plates/`. When they say images are in, list that folder for the board's save-as names. An approved plate gets its `tools/plate_compositor/plates/<plate>.json` (README §D) before any shot on it is composed; posed shots go through `extract.py` then `compose.py` (README §C, §A).

Per new draft:
1. `python .claude/skills/event-storyboard/scripts/pixelize.py <draft> .scratch/event-art/<id>/qa [--scale 4]` and **look at** the `_qa.png` sheet (source | cleaned with crop outlines | small / baseline / tall phone crops).
2. QA against the brief: story accuracy at the frozen instant, character identity vs. reference, set continuity vs. sibling shots and neighbouring events, focal point survives the small-phone crop, nothing story-critical in the bottom ~10%, no legible text/logos, no player face (unless decided otherwise), pixel-grid quality. One line each, pass/fail.
3. The raw image already shows in the tool. A cleaned version goes beside it as `<saveAs stem>[_vN]_clean.png`, and the tool lists it with the raw. Set board `phase: "drafts"`, bump `round`, rewrite `board.json`.

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

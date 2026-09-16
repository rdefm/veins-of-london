# Spec — local quest text editor

**Status:** Grilled and approved with Richard, 2026-09-04.

## Why

Quest authoring currently goes outline → brainstorm with Claude → break into chunks written
with Claude, even for pure prose passes (rewriting a line, drafting new district-event text).
That spends tokens on work that doesn't need a model at all. Richard wants a way to browse
existing quests, edit and save their text directly, and draft new quest text — all without
going through Claude for the prose itself.

## Decisions

- **Prose-only v1.** Editable fields: `text`, `label`, `speaker`, `result_text`. No editing of
  `effects`, `op`, `deck`, or flags — those stay Claude's job, to avoid silently breaking game
  state from the editor.
- **New quests are authored in the real event-JSON shape** (`data/events/<id>.json`: `id`,
  `cards` array, `choices` on choice cards) — not freeform prose. Editing an existing quest and
  drafting a new one are the same tool/workflow, not two different ones. `effects: []` and no
  `deck` key on a fresh quest.
- **Mechanic intent is captured as plain-text notes**, not inline JSON fields. A sidecar file
  `data/events/drafts/<id>.notes.md` pairs with the real JSON — free text like "spend 20 cash,
  give 1 time ore, set flag greenwichTipOff" for Claude to code later. The real JSON file is
  never touched by tool-authored non-schema keys.
- **Delivery: single static local HTML file**, opened directly in Chrome, using the File System
  Access API (`showDirectoryPicker`) to read/write `data/events/` and `data/events/drafts/`
  directly. No server, no build step, no hosting — lives in the repo like `tools/*.py`.
- **Structural editing is dynamic**, not template-locked: add/remove/reorder cards, a card-type
  dropdown (`narration`/`speaker`/`choice`/`resolution`/`craft`), add/remove choices on choice
  cards. Existing quest shapes vary too much (2 cards vs. 6, 0 choices vs. 3) for a fixed
  template to hold.
- **New quest ids are typed by hand**, not slugified from a title — validated as snake_case with
  no collision against an existing `data/events/*.json` filename. Existing naming families
  (`col_a1_*`, `archie_*`, district-named files) wouldn't survive an auto-slugifier.
- **New quests are not auto-registered.** The tool never touches `GameData.gd`'s `EVENT_IDS` /
  `DISTRICT_EVENT_IDS` consts. An unregistered file is inert — `GameData._validate_events` only
  checks ids already in those consts, so it can't break `check_all.sh` or the test suite.
  Registration (and effects/deck wiring) is a later Claude pass.
- **Editing an existing quest shows its real `effects`/`deck`/`on_complete` read-only** alongside
  the editable prose, so rewriting `result_text` doesn't drift from what a choice actually does.

## Explicitly out of scope (v1)

- Editing/generating `effects`, `op` lists, `deck` targeting, flags, or any other mechanical field.
- Auto-registering new quest ids into `GameData.gd`.
- Any server, hosting, or multi-user concerns — single local user, single local repo checkout.

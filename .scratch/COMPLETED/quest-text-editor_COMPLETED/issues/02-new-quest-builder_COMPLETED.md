# 02 — New quest builder

**What to build:** A "+ New quest" flow in the same tool that lets Richard type a new quest id
and build its card list from scratch — add/remove/reorder cards, pick each card's `type` from a
dropdown (narration/speaker/choice/resolution/craft), add/remove choices on choice cards, and
fill in the same prose fields as ticket 01's editor. Saving writes a new
`data/events/<id>.json` in the exact shape the game engine reads (per `docs/M1-LONDON.md` /
`systems/events.gd`'s card schema), with `effects: []` on every choice and no `deck` key — left
inert and unregistered for a later Claude pass to wire up.

**Blocked by:** 01 — reuses its file-list, save-to-disk, and prose-field form components.

**Status:** ready-for-agent

- [ ] "+ New quest" prompts for an id; input is validated as snake_case and rejected if it
      collides with an existing `data/events/*.json` filename.
- [ ] The card-list builder supports: add a card of any type, remove a card, reorder cards
      (e.g. up/down or drag), and — on `choice` cards — add/remove individual choices.
- [ ] Each card/choice exposes the same prose fields as ticket 01 (`text`, `label`, `speaker`,
      `result_text` on choices) for editing.
- [ ] Saving produces `data/events/<id>.json` matching the real event schema: `id`, `cards`
      array with correctly-typed entries, `choices` arrays with `effects: []`, no `deck` key.
- [ ] The produced file, added temporarily to `GameData.gd`'s `EVENT_IDS` for a manual smoke
      test, loads and plays through `systems/events.gd` without a parse/validation error — then
      removed again since ticket 02 doesn't auto-register it.
- [ ] The new file does *not* appear in `GameData.EVENT_IDS`/`DISTRICT_EVENT_IDS`, and
      `scripts/check_all.sh` / the test suite stay green with the new inert file present.

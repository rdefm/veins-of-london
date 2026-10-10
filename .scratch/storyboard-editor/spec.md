# Storyboard editor — spec

Status: needs-triage

Turn `tools/storyboard.html` from a read-only proposal previewer into the place events get **written and edited**: card text, branches, player options, checks, comments and card images — while keeping the existing shot/storyboard review workflow.

## Decisions (from interview 2026-10-10)

| Topic | Decision |
|---|---|
| Save target | Proposal `.md` files (`.scratch/writing-revamp/*.md`, the ```json block). Tool never writes `data/events/` (except optional late ticket, see Promote). |
| Saving | Manual **Save** button + **Undo** button. No autosave. |
| Device | Desktop only (Chrome/Edge, File System Access folder handle as today). |
| Branch model | **Named branches** in the draft: each branch its own card list; outcomes and cards point at a branch (optionally a card in it); branches can rejoin, conditionally. Forward only — no loops (editor blocks cycles). See Draft format. Converted to flat `goto` form on promote. |
| Branch view | **Flowchart graph**, toggle between branch-as-node (collapsed: title, card count, first line) and card-as-node (expanded). Toggle per whole graph and/or expand one branch inline. |
| Card editing | Text, speaker, label, type editable inline. Add / remove / reorder cards. |
| Player options | Add/remove options on a card. Each outcome (plain result, success/fail, per-success-count) can be assigned to an existing branch or a **new branch created in place**. |
| Checks | Both: free-text **intent note** always available ("hard Wits, ~40%, needs Archie"), plus optional real mechanics fields (base, attempts, mods, requires, effects, perSuccess, bySuccesses). Reuse quest-editor's Choice mechanics UI/logic where it helps; quest-editor stays a separate tool. |
| Comments | Two kinds: **for Claude** (actionable, open/resolved) and **note** (memory only). Attachable to card, choice/outcome, branch, whole board. |
| Proposal md prose | Logline/intro and "Open points" surface as **board-level general comments**. |
| Card image | Tap a card → pick image from: board shots, `assets/events/<id>/`, `assets/reference-plates/`, or any repo image. Picked file is **copied** to `assets/events/<id>/<id>_<branch>_<n>.png` and set as the card's explicit `image` key (so card inserts never break the mapping). HOLD / CLEAR still selectable. |
| Shots | Existing shots/briefs/review section kept, moved to its own **Shots tab** so the Storyboard tab (graph + phone preview + card editor) stays uncluttered. Shots editable. |
| New boards | Import a live `data/events/<id>.json` (flat gotos → named branches), blank new event, or duplicate an existing proposal. |
| Promote | Claude promotes on request ("promote X"): branches → flat `goto`, writes `data/events/<id>.json`, runs tests. A **Promote button** in the tool is an optional ticket at the end of the breakdown. |
| Quest editor | Stays separate. |
| Comment storage | Inside the proposal's JSON block (`_comments` / per-anchor notes), stripped on promote. One file = whole draft. |

## Required tickets (beyond the core editor)

- **Claude skill: implement a storyboard event.** User points it at an event built/edited in the storyboard tool; it actions open "for Claude" comments, converts branches → flat `goto`, writes `data/events/<id>.json`, runs tests, reports. Also covers the "promote" path above.
- **Engine routing extension** — see Required engine work; must land before promote can handle card gotos/conditions/ends.
- **Re-key shot boards to branch+card.** Shot boards in `.scratch/event-art/<board>/` key on flat card numbers; migrate to branch+card keys (and update the `event-storyboard` skill).

## Tabs

1. **Storyboard** — flowchart (top/left), phone preview of selected card (as today), card editor for selected card/branch (text, options, checks, image, comments).
2. **Shots** — current shot briefs, verdicts, prompts, uploads; plus editing of shot fields.
3. **Comments** — all comments on the board, filter by kind (for Claude / note), status, anchor.

## Draft format

```json
{
  "id": "james_meeting",
  "start": "main",
  "branches": {
    "main": { "title": "Workshop", "cards": [
      { "key": "c1", "type": "narration", "text": "..." },
      { "key": "c2", "type": "narration", "text": "...",
        "choices": [ { "id": "patient", "label": "Take your time",
          "checkNote": "steady hands, ~55% x2",
          "check": { "base": 0.55, "attempts": 2 },
          "success": { "result_text": "...", "goto": { "branch": "after" } },
          "fail":    { "result_text": "...", "goto": { "branch": "botched" } } } ] },
      { "key": "c3", "type": "speaker", "text": "...", "goto": { "branch": "after" } }
    ] },
    "botched": { "title": "James unimpressed", "cards": [ ... ],
      "then": [ { "if": { "flag": "jamesWatching" }, "branch": "watched" }, { "branch": "after" } ] },
    "after":   { "title": "Wrap-up", "cards": [ ... ], "then": "end" }
  }
}
```

- Cards carry stable auto `key`s (hidden in UI) so links survive insert/reorder.
- `goto: {branch, card?}` — on an outcome **or on any card**; omit `card` = branch's first card. No loops: editor rejects any link that creates a cycle in the card graph.
- Branch `then` — where play goes after its last card: a single `{branch, card?}`, `"end"`, or a **conditional list** evaluated in order, `if` using the existing `condition_met` vocabulary (flag, relation, cash, item, path, past choice); last entry without `if` = else. Omitted = end.
- `checkNote` = free-text check intent; `check` optional.
- Promote: branches laid out flat in topological order (start branch first) so every jump is forward, `{branch, card}` → card indexes, keys/notes/comments/`_layout` stripped. Import/older proposals: flat gotos → links, targets split into branches.

## Required engine work (`systems/events.gd`)

Today only option outcomes can `goto`, no conditional routing, no mid-list end. Stays forward-only. Ticket must add (with tests):

- **Card-level `goto`** (plain cards, not just outcomes).
- **Conditional `goto`** — ordered `[{if, card}, ..., {card}]` via `condition_met`.
- **`end: true`** — finish the event at this card.
- Needs REFERENCE.md §3.9 update for the new routing keys.

## Open points

- Graph layout: **elkjs** via CDN (layered, left→right, SVG pan/zoom; expanding a branch re-lays the graph). Dragged nodes keep their position in the draft's `_layout` (node id → [x, y]), overriding the elk layout; "Reset layout" clears it; stripped on promote.

## Relevant files

- `tools/storyboard.html` — tool being extended (`parseProposal`, `proposalCards`, `optionMech`, `outcomesOf`, `renderShots`, `saveFeedback`)
- `tools/quest-editor.html`, `tools/quest-editor-mobile.html`, `tools/test_quest_editor.js` — reusable Choice mechanics section + tests
- `.scratch/writing-revamp/*-proposal*.md` — proposal format
- `.scratch/event-art/<board>/` — shot boards
- `systems/events.gd` (`_goto_target`, next-card logic ~274, played cards ~280, `condition_met` ~447), `tests/test_events*.gd`, REFERENCE.md §3.9
- `data/events/*.json` — live event schema (cards, choices, check, goto, image)
- `CODEMAP.md` row for `storyboard.html`
- `.claude/skills/event-storyboard` — skill that drives the shot workflow; may need updating for tabs/branch keys

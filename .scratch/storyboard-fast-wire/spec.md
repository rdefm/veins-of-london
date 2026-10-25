# Storyboard fast wire

**Status:** needs-triage (proposed — awaiting user approval)

## Problem

Promote (tool button) already writes `data/events/<id>.json`. The slow part is Claude "wiring" it afterwards:

1. `implement-storyboard-event` step 3 always runs the full suite, which surfaces unrelated failures that then get fixed in the same session.
2. Card indexes are load-bearing outside the event: `choice` conditions (`{"choice": {"event", "card": <index>, "option"}}`, 9 uses, all in `buyer.json` → `cold_open` card 3) and choice memory (`flags.choices[eventId][str(cardIndex)]`). Inserting a card silently breaks them.
3. Content tests pin exact prose and positions (`test_col_a1_*` `cards[N]["text"] == ...`; playthrough/chain tests pick `choose(0)`, `choose(2)`), so text edits fail tests.
4. Content lint only exists in GDScript (`tests/test_event_content_lint.gd`); the tool can't show violations before Promote.
5. Per-wire overhead: a ticket per wiring job, broad doc reads.

## Goal

User edits in the tool, presses Promote, and the event is live. Claude involvement after a promote is a short, targeted check — not a session.

## Decisions (user, 2026-10-25)

- User presses Promote themselves; the slow step is the post-promote wiring.
- Fast lane may skip the full suite; full suite runs at commit / end of session.
- Card refs move to stable card keys. **No save migration** — old saves' index-keyed choice memory may be dropped.
- Content tests are loosened: assert on card key, flags set, or which ending was reached — never exact text.
- `tools/quest-editor.html` (desktop) is retired.

## Design (proposed)

### Stable card keys

- Promote keeps each card's `key` in the live JSON (today it strips them). Every live card has a unique `key` within its event; legacy import already preserves an existing `key`.
- `choice` condition: `"card"` takes the card's key (string). Index form is removed; lint rejects it.
- Choice memory: `flags.choices[eventId][cardKey]`. `Events.choice_record/choice_id(event_id, card_key)`.
- `_roll_key` / toggles keyed per option within the running event are unaffected (they live in `state.event`, not across events).
- `buyer.json`'s 9 refs rewritten to `cold_open`'s key.
- REFERENCE.md §2 (`choices` row) and §3.9a updated.

### Fast lane (skill)

After a tool promote, `implement-storyboard-event` picks a lane:

- **Fast** — no open "for Claude" comments: `node tools/test_storyboard.js`, content lint, and only the `tests/test_*.gd` files that mention the event id. Report. No ticket, no full suite, no doc reads beyond what a failure needs.
- **Full** — open comments to action: as today, but the full suite still defers to commit / end of session.

A failure outside the event's own tests is reported, not fixed in-session.

### Lint in the tool

- A Godot script exports the lint's reference lists (flags, items, contacts, state paths, recipe rungs, event ids + their choice-card keys/option ids) to `tools/storyboard_refs.json`.
- The lint rules are ported to JS inside the tool's "Draft model (pure)" section, run on every edit, shown in the edit bar; Promote warns (does not block) on violations.
- GDScript lint stays the authority; a test fails when the JS lint and GD lint disagree on the shipped events, or when `storyboard_refs.json` is stale.

### Impact on promote

Promote's confirm lists inbound refs: other events' `choice` conditions pointing at this event, and warns when one names a key or option the new version no longer has.

## Tickets

01 fast-lane skill · 02 stable card keys · 03 loosen content tests · 04 lint in the tool · 05 inbound-ref warning on promote · 06 retire quest-editor.html

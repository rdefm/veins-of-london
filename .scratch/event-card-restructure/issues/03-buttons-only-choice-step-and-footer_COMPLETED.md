# 03 — Buttons-only choice step + footer row

**What to build:** A choice card plays in two steps in the same text box. First its text (speaker, label, prose) shows with →. Tapping → swaps the box to the option buttons only — no event text — so the buttons are never squashed. Each button's label is its option text. Re-reading the prompt while choosing isn't needed (Rewind covers it).

A footer row is pinned to the bottom of the text box on every card: the Item button as an icon on the left (only when something is usable), → on the right (on prose cards and the prompt step). When both are absent the footer collapses and the buttons get the full height. Option buttons stack full-width, one per row.

The fixed box fits at most 4 options; the event content lint fails any choice card with more than 4.

```
┌──────────── frame ────────────┐
│          [ image ]            │
├───────────────────────────────┤
│ [ Ask about the vein        ] │
│ [ Try to bluff him          ] │
│                               │
│ [🎒]                      [→] │  ← footer row
└───────────────────────────────┘
```

**Blocked by:** 02 — Framed card, fixed text box.

**Relevant files:** `scenes/screens/event.gd` (`_fill_controls`, `_refresh_vn_card`, `_build_item_button`, `_build_continue_button`, `fits_in_row`, `_stack_height`), `systems/events.gd` (`is_awaiting_choice`, `current_card`; the prompt-step vs buttons-step marker lives in `state.event` as pure data so Rewind/save restore it), `tests/test_event_screen.gd`, `tests/test_events.gd`, `tests/test_event_content_lint.gd`, `docs/REFERENCE.md` §3.9a "Event choice checks", §3.9c "Event label tokens and content lint", `docs/ui-vision.md` §11.

**Status:** ready-for-agent

- [ ] A choice card first shows its text with →, and no option buttons
- [ ] After →, the box shows only option buttons (no event text), the Item icon if usable, and no →
- [ ] Footer: Item icon left, → right; collapses when neither shows
- [ ] Prompt/buttons step survives save/load and Rewind (state stays pure data)
- [ ] Gated options still hide or show greyed with their reason
- [ ] Content lint fails a choice card with more than 4 options; every live event passes
- [ ] Human on-device check listed: prompt → buttons swap, 1–4 buttons fit unsquashed, Item icon placement

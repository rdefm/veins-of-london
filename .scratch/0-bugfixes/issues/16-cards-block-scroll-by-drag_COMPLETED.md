# 16 — Scrolling doesn't work when a finger starts on top of a card

**What to build:** On screens like HQ, dragging to scroll only works if the gesture starts in the small gaps between item cards — if a finger lands on a card itself, scrolling does nothing, forcing the player to aim for narrow gaps. Root cause: `scenes/components/ui.gd`'s `UI.card()` builds a `PanelContainer` with no `mouse_filter` override, defaulting to `Control.MOUSE_FILTER_STOP`, which swallows the touch/drag event before it reaches `scenes/components/touch_scroll_container.gd`'s `TouchScrollContainer._gui_input()` (the custom drag-to-scroll implementation Godot's native `ScrollContainer` lacks).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `UI.card()`'s `PanelContainer` sets `mouse_filter = Control.MOUSE_FILTER_PASS` (or equivalent) so a drag starting on a card still scrolls its containing `TouchScrollContainer`.
- [ ] Audit other non-interactive wrapper containers built by `ui.gd` (list-item rows/hboxes, etc.) for the same default-`STOP` issue and fix any found the same way.
- [ ] Buttons and other interactive leaf controls inside cards still capture their own taps correctly — no regression to existing button behaviour anywhere in the app.
- [ ] On-device (or via the existing near-motionless-tap tolerance in `TouchScrollContainer`), dragging from anywhere on a card — not just the gaps — scrolls the list.

# 10 — Scrolling: drag content anywhere, no grabbable scroll bar

**What to build:** On touch, scrolling sometimes feels reversed or only works at certain spots. Likely cause: a finger landing on the scroll bar drags the bar (content moves opposite to the finger) rather than the content. Every scrolling surface should scroll by dragging content in the natural direction anywhere in it; scroll bars are not grabbable (hidden or display-only). Audit every scroll container and route them through the touch scroll behaviour.

**Blocked by:** None — can start immediately

**Relevant files:** `scenes/components/touch_scroll_container.gd`, every `ScrollContainer` under `scenes/` (phone apps, modals, screens)

**Status:** ready-for-agent

- [ ] Report lists every scroll surface audited
- [ ] All use touch-drag scrolling; scroll bars can't be dragged
- [ ] Drag direction consistent everywhere (content follows finger)
- [ ] Human checks on device: Factions, Ticker, Harrow's, Messages, BizBrief

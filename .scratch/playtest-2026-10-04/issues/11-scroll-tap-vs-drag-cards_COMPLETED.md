# 11 — Scrolling: tap vs drag on tappable cards

**What to build:** In Harrow's (and other card lists), starting a drag on a card opens the card instead of scrolling, so the player must hunt for edge space to scroll. A press that moves past a small threshold becomes a scroll and never fires the card's tap; a still press-release still opens it.

**Blocked by:** 10 — Scrolling: drag content anywhere, no grabbable scroll bar

**Relevant files:** `scenes/phone_apps/property_app.gd`, `scenes/components/touch_scroll_container.gd`, `scenes/components/turn_order_strip.gd` (existing tap-vs-drag pattern), other card-list apps in `scenes/phone_apps/`

**Status:** ready-for-agent

- [ ] One shared drag threshold, applied to all tappable cards inside scroll surfaces
- [ ] Drag on a card scrolls; tap opens
- [ ] Human checks Harrow's listings and other card lists

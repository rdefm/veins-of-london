# 02 — Dial menu: Back from a section to the overview

**What to build:** After tapping a Dial section (Movement, Lenses, Complications) there is no clear way back. Every section view gets an explicit Back button (top-left) that returns to the first Dial overview screen, using the existing zoom-out beat. Works for the HQ-opened and Profile-opened Dial alike; the overview's own Back (to HQ / Profile) is unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/dial_menu.gd` (split/zoom per section, overview bands), `scenes/screens/hq_dial.gd`, `data/dial_art.json` (layout/beat timings), `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Each section view shows a top-left Back button
- [ ] Back returns to the overview with the zoom-out beat (instant under reduced motion)
- [ ] Overview Back still exits to HQ / Profile as before
- [ ] Headless test: open section → Back → overview state

# 05 — Action button + plain observation sheet

**Phase:** MVP

**What to build:** The player can observe from the event screen. The footer's Item button becomes the **Action** button, shown when any action exists (an observation in effect, or a usable item). Its popup always opens and lists Observe first, then items. Observe opens a bottom sheet titled with the scene: one row per listed ore in fixed order physics, life, emotion, time, fate, with ore glyph and colour, roll line ("Rolled 73 · needed 40+"), tier pips (e.g. ●●○), and text; a miss shows muted text. Reopening shows the same results instantly. No animation/pulse yet (ticket 09). Placeholder icon OK. Screen only reads `Observation`/`Events` outputs and calls their functions.

**Blocked by:** 04.

**Relevant files:** `scenes/screens/event.gd`, `systems/event_items.gd` (`has_usable`, `usable_entries`), `tests/test_event_screen.gd`, `tests/test_event_items.gd`; `docs/ui-vision.md` (sheet styling, ore colours); CODEMAP.md.

**Status:** ready-for-agent

- [ ] Action button visible iff observation in effect or usable item exists
- [ ] Popup: Observe first, items after; opens even with Observe only
- [ ] Sheet rows in fixed ore order, only listed ores
- [ ] Pips reflect tier landed of n; miss styled muted with miss text
- [ ] Reopen shows identical results without rerolling
- [ ] No state mutation in the screen
- [ ] Human on-device check list in the report

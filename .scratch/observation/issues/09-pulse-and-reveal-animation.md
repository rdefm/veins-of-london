# 09 — Pulse + reveal animation

**Phase:** MVP

**What to build:** Observation feels alive. The Action button and the popup's Observe row pulse (glow/scale tween) while an unread or re-armed observation is in effect; reduced motion shows a static badge instead. The pulse returns when the scene changes to a new observation. In the sheet, rows play in sequence: d100 tick/spin (~0.5s), roll line, pips, text fades in. Tap skips to end state. Reopen is instant. Re-roll animates only improved rows. Reduced motion = no spin, quick fade. Tests assert on state flags, not timing.

**Blocked by:** 06.

**Relevant files:** `scenes/screens/event.gd`, `tests/test_event_screen.gd`; `docs/ui-vision.md` (motion, reduced motion).

**Status:** ready-for-agent

- [ ] Pulse flag on while unread/re-armed; off after reading
- [ ] Reduced motion: static badge, no tween
- [ ] Pulse reappears on scene change to a new observation and after Rewind re-arm
- [ ] Sequenced row reveal; tap skips to end state
- [ ] Reopen instant; re-roll animates only improved rows
- [ ] Human on-device check list in the report

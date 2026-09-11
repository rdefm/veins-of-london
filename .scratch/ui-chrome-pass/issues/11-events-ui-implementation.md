# 11 — Implement new Events UI chrome

**What to build:** Re-skin `scenes/screens/event.gd` per the design spec
from ticket 10 — remove the hardcoded `AMBER_COLOR`/`AMBER_BG`/
`DANGER_COLOR` constants in favour of the chosen family/treatment. Card
content, scroll behaviour (bottom-anchored `ScrollContainer`, cards
accumulate upward), and the action bar's Continue/Rewind/choice logic are
unchanged — rendering pass only.

**Blocked by:** 10

**Status:** ready-for-agent

- [ ] All event card types render per the ticket-10 spec; no hardcoded amber constants remain in `event.gd`
- [ ] Scroll-to-bottom-on-new-card behaviour and action bar (Continue/Rewind/choice buttons, safe-area inset handling) unchanged
- [ ] Verified against at least one narration card, one choice card, and one craft/resolution card on-device or via screenshot
- [ ] `tests/test_event_screen.gd` updated for the new styling if it asserts on visuals

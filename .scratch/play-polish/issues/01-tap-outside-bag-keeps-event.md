# 01 — Tapping outside the Bag can't touch the screen underneath

**What to build:** During a raid event, the player opens the Bag from the top bar, then taps outside it to close it. Today the event disappears and they land in the normal game. After this ticket, tapping outside closes only the Bag, and the event stays on the same card.

Start with a repro. The leading hypothesis is tap-through and is unproven: the touch press closes the drawer, then the emulated mouse click reaches the event option underneath (for example a "Back out" option). Neither `Bag.close()` nor item use clears the event. If the repro points elsewhere, fix the real cause.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/bag_drawer.gd` (`_on_dim_gui_input`), `scenes/components/touch_input.gd` (`is_emulated_mouse`), `scenes/Main.gd` (`_input`, prior art for emulated-mouse handling), `systems/bag.gd`, `scenes/screens/event.gd`

**Status:** ready-for-agent

- [ ] A repro of the bug is recorded in the ticket's `## Comments`, with its confirmed cause
- [ ] Tapping outside the Bag during an event closes the Bag, with the same event and card still showing
- [ ] Mouse and touch input both work, on event, combat and normal screens
- [ ] The tap that closes the Bag never activates anything underneath
- [ ] Bag Close button and item use still behave as before
- [ ] Automated test covers the fix at the highest seam that reproduces it
- [ ] Human on-device check is listed in the task report

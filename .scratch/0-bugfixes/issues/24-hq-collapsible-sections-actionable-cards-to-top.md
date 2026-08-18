# 24 — HQ: collapsible Rooms/Security sections, actionable cards to top

**What to build:** On the HQ screen (`scenes/screens/hq.gd`), the "Security (n/n)" and "Rooms (n/n)" lists are always fully expanded flat lists, pushing actionable cards (Lab, Rest, workbench actions) far down the screen. Make Rooms and Security sections collapsible (accordion-style — no such primitive exists yet in `scenes/components/ui.gd`, so this adds one), and reorder the screen so actionable items (Lab, Rest, Recipes/Workbench actions) sit at the top, above the passive Rooms/Security lists.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A collapsible/accordion section component exists (new, in `scenes/components/ui.gd` or similar) and is reusable.
- [ ] "Rooms" and "Security" sections in `HqScreen._refresh()` are collapsible using it, default state decided (collapsed or expanded — flag for human sign-off if ambiguous).
- [ ] Actionable cards (Lab, Rest, Recipes/Workbench "Begin"/"Attempt" actions) are reordered to the top of the screen, above Rooms/Security.
- [ ] Collapse state persists sensibly across a screen refresh within a session (doesn't need to survive save/load unless trivial).
- [ ] `hq` tests updated to cover the new layout/collapse behavior.

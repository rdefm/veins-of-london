# 142 — Losing a vein clears its cultivator assignment

**What to build:** When the player loses a vein by any route (sold, raided, Collective, cultivation loss), it is removed from whichever cultivator's list held it and its hold target is dropped. Today nothing unassigns it, so e.g. assigning Owen, selling the vein and repeating leaves him "assigned to 4 veins" while the player owns 2. Existing saves are repaired on load: every cultivator list is stripped of vein ids the player no longer owns.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/sites.gd` (`release_vein_slot` — shared by every removal path: `systems/vein_trade.gd` ~L63, `systems/raiding.gd` ~L400, `systems/collective.gd` ~L630, `systems/cultivating.gd` ~L532), `systems/rooms.gd` (`unassign_vein`, `cultivator_veins`, `cultivators`), `autoload/SaveManager.gd` (load backfill), `systems/owen_texts.gd` (live-vein check); REFERENCE.md §3.10 "Staff roles".

**Status:** ready-for-agent

- [ ] Selling an assigned vein removes it from the cultivator's list and drops its station target; tested
- [ ] Same for raid/Collective/cultivation-loss removal paths (via the shared release path); tested
- [ ] Loading a save with stale vein ids in `cultivatorVeins` strips them; tested
- [ ] Human on-device: assign Owen, sell the vein, assign to another — Staff tab count matches veins actually owned

# 12 — Dial access and casting from events (general)

**What to build:** In any event (not just raids), an item toggle can be paid for with a loaded Dial complication as well as from inventory: inventory first, then a loaded complication of that recipe, matching how event Rewind already pays. The effect applied is identical whichever source paid, through the payment-source parameter of ticket 03's resolver. The toggle shows when the player has the item in inventory or loaded on the Dial, and says which source will pay. A cast complication is spent like a consumed item (Rewind restores it, via the snapshot).

**Blocked by:** 08 — Proposal; 09 — Raid event pool; 10 — Raid event A; 11 — Raid event B; 13–18 (engine tickets); 19 — Rebuild `vein_raid`; and the per-beat prose tickets ticket 08 creates.

**Relevant files:** `systems/events.gd` (toggles ~L742-807, Rewind payment ~L838), `systems/dial.gd` (`find_loaded_rewind_complication_index()` and complication lookup), `systems/combat.gd` (`COMBAT_COMPLICATION_RECIPES`, `_round_dial()` for the combat pattern), `scenes/screens/event.gd` (toggle UI ~L566), `tests/test_event_items.gd`, `tests/test_dial.gd`, `docs/REFERENCE.md` §3.5 Crafting & the Dial, §3.9a.

**Status:** ready-for-agent

- [ ] Toggle available with the item only on the Dial; pays from the Dial when inventory is empty
- [ ] Inventory preferred when both are available
- [ ] Tests: same effect from either source; complication spent on a failed roll; Rewind restores it
- [ ] REFERENCE.md §3.5 / §3.9a updated
- [ ] Human on-device check: toggle label shows the Dial source; the complication empties after commit

# 03 — Item effect engine + Enhancement Powder `bonus` (tracer bullet)

**What to build:** Event item toggles (the existing "use X" switch on an option) carry a typed item effect instead of only a check delta. Effect kinds: `bonus`, `unlock`, `bypass`, `remove`, `fightStart` — this ticket builds the resolver and `bonus`; later tickets add the other kinds through the same resolver.

Rules (from the raid-events spec + grilling):
- Effects apply only when the item is toggled and the option committed. No passive hold bonus.
- The item is consumed on commit whether the roll succeeds or fails. Items never fail; only the roll/threshold can.
- An item may be used again later in the same event if the player holds more.
- Lasting effects persist for the rest of the event: Enhancement Powder used once gives its bonus on every later physical-entry check in that event. Persistence lives in the event's run state (pure data) and clears when the event ends.
- Rewind refunds a consumed item (it restores the snapshot).
- Paying for the effect is a separate step from applying it: the resolver takes the item and a payment source, so ticket 12 can add a Dial cast as a second source without touching effect code. This ticket implements the inventory source only.

Tracer: `vein_raid`'s physics approach (a physical entry) gets an Enhancement Powder `bonus`. Numbers are placeholders until playtest.

**Blocked by:** 01 — Remove the passive `observeBonus` hook.

**Relevant files:** `systems/events.gd` (consume on commit ~L404, `item_toggles()`/`toggle_item()`/active toggles ~L742-807, `_mod_delta()`), `systems/crafting.gd` (`inventory_remove`, `inventory_qty`), `data/events/vein_raid.json`, `data/` recipes (enhancementPowder), `tests/test_event_items.gd`, `tests/test_raiding.gd`, `docs/REFERENCE.md` §3.9a Event choice checks, §3.9 Snapshots & Rewind.

**Status:** ready-for-agent

- [ ] Item effect schema documented in REFERENCE.md §3.9a (kind + payload per kind)
- [ ] One resolver applies effects; payment source is a parameter (inventory implemented)
- [ ] Tests: consumed on failed roll; no bonus when held but not toggled; Powder bonus persists across later physical-entry checks in the same event and not into the next event; second use allowed; Rewind refunds the item
- [ ] `vein_raid` physics approach offers the Powder toggle and the bonus shows in the odds breakdown
- [ ] Human on-device check: toggle Powder, odds rise, item count drops after commit

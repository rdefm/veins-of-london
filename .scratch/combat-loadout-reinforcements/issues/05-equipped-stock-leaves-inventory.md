# 05 — Equipped units leave available inventory everywhere

**What to build:** Every flow outside combat treats equipped units as gone from available stock: selling/trade, business, stash moves, gifts, guard-kit stocking, event item hooks and out-of-combat item use all read only unequipped inventory. No flow can spend or move a unit that sits in a personal slot.

**Blocked by:** 04

**Relevant files:** `systems/event_items.gd`, `systems/consumables.gd`, `systems/diplomacy.gd` (gifts), `systems/guard_kit.gd` (stock source), trade/sell systems (`systems/economy.gd`, sell menu), `systems/business.gd`, stash code in `systems/home.gd`, `tests/test_event_items.gd`, `tests/test_consumables.gd`, `tests/test_guard_kit.gd`. Update REFERENCE §2 if inventory semantics are described there.

**Status:** ready-for-agent

- [ ] With all of a recipe equipped, sell/gift/stock/event-use/out-of-combat-use show zero available and refuse
- [ ] With some equipped, only the remainder is offered
- [ ] Tests cover at least sell, event hook, guard-kit stocking and gift

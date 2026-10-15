# 16 — Harassment actions: economic and information

**What to build:** Authored harassment cards can hit the player's economy and information. Event actions:
- a sell-price penalty for item or ore classes (Guild decertified batches, Network rumours)
- a bar from a faction shop (Guild)
- a raise to every faction's intel on the player (Network leak)

Placeholder cards cover the Guild and Network menus.

**Blocked by:** 14 — Harassment rung core

**Relevant files:** `systems/events.gd` (runner, whitelist), `systems/economy.gd` (sell prices), `systems/market.gd`, `data/faction_trade.json` / `systems/map_pins.gd` (shop availability), `systems/intel.gd`, `scenes/modals/sell_menu_view.gd` (show penalty), placeholder events in `data/events/`, tests: economy, intel, `test_harassment`. REFERENCE.md action list, Harassment §.

**Status:** ready-for-agent

- [ ] Price penalty applies to the right item/ore classes in all sell lanes until expiry or clear
- [ ] Shop bar hides/blocks that faction's shop while active
- [ ] Intel leak raises every faction's intel meter on the player
- [ ] Each tested through the Events action runner
- [ ] Placeholder cards flagged `PROSE-REVIEW`

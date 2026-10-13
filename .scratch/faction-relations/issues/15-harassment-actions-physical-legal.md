# 15 — Harassment actions: physical and legal

**What to build:** Authored harassment cards can now hurt physically and through the system. Event actions, registered in the Events action runner and whitelist:
- degrade a vein's security tier until repaired, and mark it repaired (Firm: tampered locks/cameras)
- apply/clear a vein work ban for a block of the day (Collective: noise complaint)
- freeze a vein by injunction (Conclave)
- fine
- spend a time block on a hearing

Placeholder cards cover the Firm, Collective and Conclave menus.

**Blocked by:** 14 — Harassment rung core

**Relevant files:** `systems/events.gd` (action runner ~line 780, whitelist), `systems/cultivating.gd` (security tiers, cultivate/tend gating), `systems/time_system.gd` (blocks), `systems/vein_list.gd` / vein detail readers for frozen/banned state, `scenes/components/vein_detail_panel.gd` (show state), placeholder events in `data/events/`, tests: events, cultivating, `test_harassment`. REFERENCE.md §3.9a-adjacent action list, Harassment §.

**Status:** ready-for-agent

- [ ] Each action changes state as specified and records a `state.harassment.active` entry where persistent
- [ ] Degraded security lowers raid resist until repaired; repair costs £ (data)
- [ ] Work ban blocks actions on that vein for the given block; freeze blocks all actions until expiry
- [ ] Fine deducts cash; hearing spends a block
- [ ] Each tested through the Events action runner
- [ ] Placeholder cards flagged `PROSE-REVIEW`; UI QA list in the report

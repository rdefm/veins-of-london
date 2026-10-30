# 06 — Time Pearl: sneak past a timed patrol

**What to build:** In `vein_raid`, a player who observed the patrol's timing (time observation) and toggles a Time Pearl slips past the guard on patrol. The trade-off: the later entry check in the same event carries a penalty (low roll). The pearl is consumed on commit; the penalty is a lasting effect for the rest of the event, held in the event's run state like Powder's bonus (ticket 03).

Numbers are placeholders. Placeholder prose; real prose lands in ticket 07.

**Blocked by:** 02 — Locked approaches greyed with reasons; 03 — Item effect engine.

**Relevant files:** `systems/events.gd` (item effect resolver, check mods), `systems/observation.gd` (`observed()`), `data/events/vein_raid.json`, `tests/test_raiding.gd`, `tests/test_event_items.gd`, `docs/REFERENCE.md` §3.9a, §3.9d.

**Status:** deprecated

> **DEPRECATED (2026-10-30):** Raids are moving to multi-stage approaches (stage trees). Time Pearl's raid uses (e.g. freeze guards to rush past, take out the line guard) are decided in 08's grilling/proposal and built in 10/11/19. Do not implement.

- [ ] Sneak approach greyed without time observation or Time Pearl; `?` lists what is missing
- [ ] Sneak skips the patrol fight; the later entry check shows the penalty in its odds breakdown
- [ ] Tests: penalty applies to the entry check only within this event; pearl consumed even if the entry roll fails
- [ ] Human on-device check: sneak row, then the entry row's lower odds

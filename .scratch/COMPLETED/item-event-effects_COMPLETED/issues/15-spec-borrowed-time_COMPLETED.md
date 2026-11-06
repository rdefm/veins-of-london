# 15 — Spec: Borrowed Time (time-block loan)

**What to build:** A small spec plus a sim. Borrowed Time gives +1 time block today and costs −1 block tomorrow, with higher tiers reducing the debt (brainstorm §3.3, §6 Tier C). Answer: can it stack? Does it interact with Rest? What happens to the debt if the day rolls over during an event? Run a sim before committing.

**Blocked by:** 01

**Relevant files:** `docs/brainstorm.md`, `systems/time_system.gd`, `systems/calendar.gd`; REFERENCE §1.11 Misc constants (`TIME_BLOCKS`).

**Status:** ready-for-human

- [ ] Spec answers the three questions; the human signs it off
- [ ] Ticket 16 updated with the agreed rules

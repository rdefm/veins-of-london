# 29 — Grilling: muscle (hired guards and soldiers)

**What to build:** A grilling session (the `grilling` skill) with the human, then a spec, for a "muscle" system: the player (and factions) hire and manage people who act as guards and soldiers. Muscle can be allocated as guards on veins, as guards on HQ, or held in reserve to answer alarm calls. Muscle can be trained and equipped. Raid reinforcements (23) then draw from the owning faction's muscle pool instead of the flat placeholder +2. No code in this ticket.

The grilling must settle at least:
- how muscle relates to today's guards (vein guard slots, `extraGuards`, HQ `guardCount`, guard wages, guard kit): replace, wrap, or sit beside
- hiring, wages and upkeep; where muscle comes from (contacts, factions, districts)
- allocation: veins, HQ, reserve; how a reserve answers an alarm (response time in raid cards, how many come)
- training (stats, levels) and equipment (guard kit, weapons), and how both show up in fights
- faction muscle pools and how factions spend and lose them
- what changes in raid reinforcements (23) and the stockpile raid's guards

Output: `.scratch/muscle/spec.md` with the decisions at the top, handed to the human for approval. Ticket breakdown only after approval.

**Blocked by:** 10 — The Arches; 11 — The Shop; 19 — Rebuild `vein_raid`; 26–28 — Prose (the raid work built and tested first).

**Relevant files:** `systems/guard_upkeep.gd`, `systems/guard_kit.gd`, `systems/cultivating.gd` (`vein_guard_count`, `drop_vein_guard`), `systems/home.gd` (`guardCount`), `systems/factions.gd` (`apply_security_upgrades()`), reinforcement clock from 23, `CONTEXT.md`, `docs/adr/`, REFERENCE.md §1.6 (guards, guard kit), §1.8 (faction guard hiring and wages), §3.12 Vein raiding.

**Status:** ready-for-human

- [ ] Grilling session held; decisions recorded at the top of the spec
- [ ] Spec covers the points above
- [ ] Human approval recorded in the spec
- [ ] Not marked `_COMPLETED` before approval

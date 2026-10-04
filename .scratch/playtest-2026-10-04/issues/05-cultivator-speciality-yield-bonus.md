# 05 — Cultivator speciality: +20% yield

**What to build:** A hired cultivator's ore specialities now matter: when they prune a vein whose ore type is one of their specialities, yield is +20% (rounded per existing yield rounding). They still work all ore types. LodedInnit profile text reflects the bonus instead of treating specialities as flavour.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/rooms.gd` (`_cultivator_act`), `systems/cultivating.gd` (`prune_yield`), `systems/hiring.gd`, `systems/lodedinnit_profile.gd`, `data/hiring.json` (`specialities`), `data/constants.json` (bonus value lives in data), `docs/REFERENCE.md` §3.4, §3.10 "Hiring"

**Status:** ready-for-agent

- [ ] Bonus value in JSON, not code
- [ ] Speciality-ore prune yields +20%; non-speciality unchanged
- [ ] Cultivators without specialities (founders) unaffected
- [ ] Profile UI states the bonus
- [ ] REFERENCE.md §3.10 updated (drop "a Cultivator's are flavour"); tests pass

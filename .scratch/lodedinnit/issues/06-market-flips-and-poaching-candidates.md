# 06 — Market flips + poaching employed candidates

**What to build:** Candidates' availability changes over time. At each rollover every candidate not working for the player flips between "Open to work" and "Employed at {faction}" with chance 1/14 (Rewind-safe `Rng`); a new employer is a random faction from the pool. Profiles and the People list show the status. The player can still hire an employed candidate ("Poach"), at a permanent ×1.25 wage (`wageMult`), costing −8 relation with that faction.

**Blocked by:** 04 — LodedInnit app: hire an open candidate.

**Relevant files:** `systems/hiring.gd`, `data/hiring.json` `market`, `systems/time_system.gd` (rollover step), `systems/factions.gd` (`adjust_player_relation` ~L29), `autoload/Rng.gd`, lodedinnit app, spec §1 C5/C6, §4.1, §4.2, §10 R2/R5, REFERENCE.md §2 + §3.10.

**Status:** ready-for-agent

- [ ] Flip rate and employer pool tested with a seeded Rng; `ours` never flips
- [ ] Poach applies the premium and relation cost; open hires don't
- [ ] Status survives save/load and Rewind
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: People list shows Open / Employed at X; Poach button shows the premium wage and relation warning

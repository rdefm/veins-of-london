# 05 — Wage scales with level; let go

**What to build:** A hire's weekly wage follows `baseWage + wagePerLevel × (level − startLevel)`, × `wageMult` (1 for now), and updates when they level up. The player can let a hire go from the HQ room card. That frees their seat and releases their cultivated veins. Their wage entry is flagged leaving, the next payday settles their prorated owed and then removes it, and they return to the market as Open. Their level is kept, and a re-hire costs the formula wage at that level.

**Blocked by:** 04 — LodedInnit app: hire an open candidate.

**Relevant files:** `systems/hiring.gd`, `systems/contacts.gd` (`award_contact_xp` level-up hook), `systems/rooms.gd` (`cultivatorVeins` ~L180-231), `systems/business.gd` (`_payday`), `scenes/screens/hq_floorplan.gd`, lodedinnit app (profile wage), spec §4.2, §10 R2/R3/R4, REFERENCE.md §3.10.

**Status:** ready-for-agent

- [ ] Level-up raises `weekly`; capped candidates (e.g. Bernie) never rise
- [ ] Let go frees the seat and releases the veins; payday pays the leaving entry once, then deletes it
- [ ] Re-hire wage reflects current level
- [ ] REFERENCE + CODEMAP updated
- [ ] Human check: HQ room card has Let go; profile wage updates after a level-up

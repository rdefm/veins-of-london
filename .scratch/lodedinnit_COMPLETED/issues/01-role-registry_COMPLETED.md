# 01 — Role registry (prefactor)

**What to build:** Staff roles come from a data registry instead of hardcoded tables, so later roles are a data entry. The registry has cultivation and production enabled, sales and security disabled (spec §2). There is no behaviour change, so every existing test stays green.

**Blocked by:** None — can start immediately.

**Relevant files:** new `data/hiring.json` (`roles`), `autoload/GameData.gd`, `systems/contacts.gd` (`ROOM_ROLES`), `systems/payroll.gd` (`ROLE_SKILL_KEYS`), `autoload/SaveManager.gd` (~L532 founder role backfill), `.scratch/lodedinnit/hiring-spec.md` §2, REFERENCE.md §3.10 Contacts, rooms, jobs, CODEMAP.md.

**Status:** ready-for-agent

- [ ] `hiring.json` `roles` loaded by GameData, exactly as spec §2
- [ ] Room→role and room→skill lookups derive from the registry; no hardcoded table left
- [ ] Full suite green, no behaviour change
- [ ] CODEMAP + REFERENCE §3.10 updated

# 01 — Founder roles, skill caps, Owen roster, save fix-ups

**What to build:** Archie, James and Owen become "founders" who can hold a staff role (Sales / Cultivation / Production) without any room. Owen exists in the contact roster (hidden until Beat 3). Relation recruitment is gone for Archie and James. Per-contact skill caps stop XP level-ups at the cap. Old saves load cleanly: Archie is recruited if past the home raid, and any founder sitting in a room is converted to the matching role. Payroll never charges founders a daily wage. Sales is "staffed" when anyone holds the Sales role.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/contacts.gd`, `systems/contracts.gd` (`has_staffed_sales`), `systems/payroll.gd` (`pay_wages`), `data/constants.json` (contacts roster), `autoload/GameState.gd`, `autoload/SaveManager.gd`, `tests/test_contacts.gd`, `tests/test_payroll.gd`, `tests/test_savemanager.gd`; REFERENCE.md §2 STATE SCHEMA, §3.8 Home-raid event chain, §3.10 Contacts, rooms, jobs; spec §"Contacts and roles".

**Status:** ready-for-agent

- [ ] Contacts gain `assignedRole` (`null|"sales"|"cultivation"|"production"`), exclusive with `assignedRoom` (setting one clears the other); one role per contact; several contacts may share a role
- [ ] Only `roomFreeRoles: true` contacts (Archie, James, Owen) may hold a role without a room; other hires get a role only by staffing the matching room (Operations Room → Sales, Vein Cultivation Station → Cultivation, Improved Lab → Production)
- [ ] Role availability exposed as queries that later tickets unlock via flags (Archie Sales from Beat 2; Owen Cultivation from Beat 3, Production after his crafting event; James Production from Beat 5)
- [ ] Owen roster entry: not unlocked, `recruitable: false`, `combatHpMax: 0`, `skillCaps: {cultivating: 3, crafting: 3}`
- [ ] Optional `skillCaps` honoured: contact-XP level-up loop stops at `min(ladder max, cap)`
- [ ] Archie and James `recruitable: false`; no Recruit button for them; mechanism intact for other contacts
- [ ] Load fix-up: `homeRaidEventSeen` true → Archie recruited
- [ ] Load fix-up: founder with non-null `assignedRoom` → matching `assignedRole`, room cleared
- [ ] `Contracts.has_staffed_sales()` true iff any contact holds the Sales role (room or founder)
- [ ] `Payroll.pay_wages()` skips founders; room hires keep `£100 + £50 × (skill − 1)`
- [ ] Tests: save with Archie in a room loads as Sales role; old save past home raid loads Archie recruited; Owen XP never passes cap 3
- [ ] REFERENCE.md §2 / §3.8 / §3.10 and CODEMAP.md updated

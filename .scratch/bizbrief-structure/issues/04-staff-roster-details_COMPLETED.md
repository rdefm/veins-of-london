# 04 — Scannable Staff roster and person details

Status: ready-for-agent

**What to build:** Staff presents one concise status row per recruited person. Opening a person reveals role, skills, pay and assignments, with current payroll and role actions intact.

**Blocked by:** 03 — Procurement workstream and vein chooser.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/contacts.gd`, `systems/business.gd`, `systems/hiring.gd`, `tests/test_phone_bizbrief.gd`, `docs/REFERENCE.md` §3.10 Hiring, Business pot and payday, `CODEMAP.md`.

- [ ] Staff unlock remains unchanged; roster rows identify person, role and working/owed status at a glance.
- [ ] Person detail retains skills/caps, founder role choices, wage terms, owed-pay action and its insufficient-cash disabled state.
- [ ] Assignments link lands on the relevant Procurement controls; a person with no business wage does not acquire a pay action.
- [ ] Pending poach match/decline controls have a specific person's destination for ticket 06 to link into.
- [ ] Focused Godot 4.7 tests pass; human checks roster and person-detail legibility on-device.

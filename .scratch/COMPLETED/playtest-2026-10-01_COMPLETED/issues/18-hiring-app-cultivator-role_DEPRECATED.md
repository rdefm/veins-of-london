# 18 — Hiring app: hire a cultivator end to end

**What to build:** Per the approved spec (17): the hiring phone app with role registry, candidate roster data, and the cultivator role. Player browses candidates, meets requirements, hires; the hire becomes a staff contact with their start level/cap/personality, can be assigned to a cultivation room and veins, and draws wages through payroll.

**Blocked by:** 17 — Hiring app design doc.

**Relevant files:** spec from 17, `systems/contacts.gd`, `systems/payroll.gd`, `systems/rooms.gd`, `systems/cultivating.gd`, `systems/phone_apps.gd`, `scenes/phone_apps/phone_app_registry.gd`, `autoload/SaveManager.gd`, CODEMAP.

**Status:** ready-for-agent

- [ ] Hiring system + data, tested (hire, requirements, wage, level cap)
- [ ] App shows candidates; hire flow works
- [ ] Hired cultivator works veins like existing staff
- [ ] PROSE-REVIEW: candidate profiles / app strings
- [ ] Human check: browse → hire → assign → cultivates next block

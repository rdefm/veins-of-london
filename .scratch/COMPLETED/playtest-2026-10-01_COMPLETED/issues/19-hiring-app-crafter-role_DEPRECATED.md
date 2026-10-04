# 19 — Hiring app: crafter role

**What to build:** Add the crafter role to the hiring registry: crafter candidates with speciality ore types, start level/cap, personality. Hired crafters appear in Production and craft recipes per the speciality rule from 10.

**Blocked by:** 18 — Hiring app cultivator role; 10 — Crafter specialities.

**Relevant files:** spec from 17, hiring system/data from 18, `systems/rooms.gd`, `scenes/phone_apps/bizbrief_app.gd`, `systems/crafting.gd`, `data/recipes.json`, CODEMAP.

**Status:** ready-for-agent

- [ ] Crafter role added as registry/data entry only (no special-casing)
- [ ] Hired crafter's Production list obeys their specialities; tested
- [ ] PROSE-REVIEW: crafter candidate profiles
- [ ] Human check: hire crafter → set production → items made

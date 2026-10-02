# 17 — Hiring app (VfL LinkedIn parody): design doc

**What to build:** A spec at `.scratch/playtest-2026-10-01/hiring-spec.md` for a phone app parodying LinkedIn where the player hires staff. Must cover:
- Role registry: cultivators and crafters plug in now; security and other roles slot in later without rework
- Hand-written roster of named candidates, each with starting level, level cap, speciality ore types (crafters; maybe cultivators), personality (gameplay effect if any + text voice), hire requirements (e.g. HQ room, reputation, questline flags)
- Cost: wage only, no signing fee — assumed paid through existing weekly payroll (flag as open question)
- Candidate availability / refresh cadence
- Integration with contacts, rooms, `cultivatorVeins`, production specialities (ticket 10)
- Save shape, app name/branding, open questions for the human

**Blocked by:** 10 — Crafter specialities.

**Relevant files:** `systems/contacts.gd`, `systems/payroll.gd`, `systems/rooms.gd`, `systems/phone_apps.gd`, `scenes/phone_apps/phone_app_registry.gd`, `data/constants.json` (roster, skillCaps, roleFlags), CONTEXT.md, `docs/adr/`, `docs/ui-vision.md`, `docs/CONTENT-GUIDE.md`.

**Status:** ready-for-human

- [ ] Spec written, open questions listed
- [ ] Human approves before 18 starts

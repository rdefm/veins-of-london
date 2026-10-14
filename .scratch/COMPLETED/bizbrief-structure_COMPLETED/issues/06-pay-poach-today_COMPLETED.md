# 06 — Put pay and poach decisions in Today

Status: ready-for-agent

**What to build:** A pending wage or staff poach decision appears once in Today's priority area. Its action opens that person's detail, where the existing payment or match/decline decision can be made.

**Blocked by:** 04 — Scannable Staff roster and person details; 05 — Focused Today hierarchy and exact action routes.

**Relevant files:** `systems/daily_brief.gd`, `data/daily_brief.json`, `scenes/phone_apps/bizbrief_app.gd`, `systems/business.gd`, `systems/hiring.gd`, `tests/test_daily_brief.gd`, `tests/test_phone_bizbrief.gd`, `.scratch/bizbrief-today/spec.md`, `docs/REFERENCE.md` §3.10 Hiring and Business pot and payday, `CODEMAP.md`.

- [ ] Each pending wage or poach decision appears once, under Urgent, with person, amount/deadline and consequence from live state.
- [ ] Tapping the row opens that person's decision controls; Yes/No, top-up, Match and Let them go keep their existing validation and effects.
- [ ] The separate duplicate Brief alert cards are removed; resolved decisions disappear from Today, and the badge follows the existing Urgent + Story rule.
- [ ] Data-driven new copy is flagged `PROSE-REVIEW:`; focused Godot 4.7 tests cover pending, resolved, insufficient-cash and gated Staff cases.

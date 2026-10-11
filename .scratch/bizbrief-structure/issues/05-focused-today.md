# 05 — Focused Today hierarchy and exact action routes

Status: ready-for-agent

**What to build:** Brief opens on the Focused Brief A Today layout: compact, full-width actionable rows under visibly distinct Urgent, Story, Opportunity and Routine headings. A row opens its actual subject, including the exact Sales offer or contract.

**Blocked by:** 01 — Compact BizBrief shell and Sales workstream.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/daily_brief.gd`, `data/daily_brief.json`, `tests/test_phone_bizbrief.gd`, `tests/test_daily_brief.gd`, `.scratch/bizbrief-today/spec.md`, `docs/reviews/review-2026-10-09.md` §21, `CODEMAP.md`.

- [ ] Today leads Brief after Rest and when opened manually; date and blocks left remain readable at phone width.
- [ ] Urgent → Story → Opportunity → Routine order, consequence text, row cap/expansion, done ticks, empty state, reduced-motion behaviour and Urgent + Story badge semantics remain.
- [ ] Rows use compact full-width text and one clear route; offer and contract actions land on the named item, and other existing destinations still work.
- [ ] The prior Today presentation spec is amended for the approved layout; no business thresholds or formulas change.
- [ ] Focused Godot 4.7 tests pass; human checks one-screen scanning, touch targets and long-list scroll on-device.

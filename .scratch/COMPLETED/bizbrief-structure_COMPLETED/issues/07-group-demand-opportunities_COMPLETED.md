# 07 — Group simultaneous demand opportunities

Status: ready-for-agent

**What to build:** When several held goods meet the existing demand-spike rule, Today shows one opportunity summary. Opening it lists each qualifying good and a Sell route, so market news does not fill the Brief.

**Blocked by:** 05 — Focused Today hierarchy and exact action routes.

**Relevant files:** `systems/daily_brief.gd`, `data/daily_brief.json`, `scenes/phone_apps/bizbrief_app.gd`, `tests/test_daily_brief.gd`, `tests/test_phone_bizbrief.gd`, `.scratch/bizbrief-today/spec.md`, `docs/REFERENCE.md` §3.2 Barometer and §3.13 London market, `CODEMAP.md`.

- [ ] Two or more qualifying held goods form one summary; one qualifying good retains a direct opportunity row; none adds no row.
- [ ] Detail names every qualifying good, held quantity and existing demand signal, and each Sell route opens the existing Trade path.
- [ ] Grouping changes presentation and visible-row counting only: eligibility threshold, price math, tier priority, Urgent + Story badge and done-state truth remain intact.
- [ ] Today spec and data-driven copy are updated; new prose is flagged `PROSE-REVIEW:`. Focused Godot 4.7 tests cover one, many, none and the row cap.

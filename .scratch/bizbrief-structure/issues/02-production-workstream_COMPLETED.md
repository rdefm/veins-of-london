# 02 — Production workstream

Status: ready-for-agent

**What to build:** Manage → Production opens a short, dedicated page. Players first see what each recipe is targeting and covering, then adjust targets or inspect the production log.

**Blocked by:** 01 — Compact BizBrief shell and Sales workstream.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/rooms.gd`, `tests/test_phone_bizbrief.gd`, `docs/REFERENCE.md` §3.10 Producer, `CODEMAP.md`.

- [ ] Manage shows a live Production status and opens the Production page directly.
- [ ] Recipe rows show personal target, contract need and coverage state before detailed controls; existing limits and production gating remain.
- [ ] Target changes, cover-contract toggle and per-day production log retain their current behaviour, including empty/locked states.
- [ ] A Today action aimed at production can land on this page. Focused Godot 4.7 tests pass; human checks control density and scroll on-device.

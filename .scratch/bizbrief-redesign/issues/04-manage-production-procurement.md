# 04 — Manage production and procurement

**What to build:** Below Sales, Manage presents the selected compact Production and Procurement sections. Players can still set personal recipe targets, cover contract needs, read the production log, assign cultivators to veins, and change vein targets. Section links reveal or jump to the existing controls within Manage.

**Blocked by:** 01 — BizBrief app chrome.

**Status:** ready-for-agent

**Relevant files:** `.scratch/bizbrief-redesign/spec.md`; `.scratch/bizbrief-redesign/selected-direction.html` (Manage); `scenes/phone_apps/bizbrief_app.gd`; `systems/rooms.gd`; `systems/contacts.gd`; `tests/test_phone_bizbrief.gd`; `docs/REFERENCE.md` §2 lab/procurement state, §3.10 Production, Procurement and producer priority; `CODEMAP.md` if ownership/files change.

- [ ] Recipe rows show live personal target and contract need, preserve target bounds and cover toggle, and show the existing Improved Lab/availability states.
- [ ] Production log still shows its current day, block, crafter, made/failed and shortage details through an in-tab Log control.
- [ ] Procurement shows assigned veins and live targets; assign, unassign and ±5 controls still invoke existing systems. No cultivator, no vein, and room-gated states remain clear.
- [ ] Production and Procurement fit the approved row/card hierarchy without changing quantities or simulation rules.
- [ ] Focused headless checks cover controls and gates; all tests pass. Report on-device checks for long lists, sliders/steppers, and log expansion.

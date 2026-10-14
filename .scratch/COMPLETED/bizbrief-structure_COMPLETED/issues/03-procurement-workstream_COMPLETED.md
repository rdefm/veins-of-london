# 03 — Procurement workstream and vein chooser

Status: ready-for-agent

**What to build:** Manage → Procurement shows each cultivator's assigned veins and opens one chooser to assign a vein. Players no longer scan a repeated list of every available vein under every cultivator.

**Blocked by:** 01 — Compact BizBrief shell and Sales workstream.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `systems/rooms.gd`, `systems/vein_list.gd`, `tests/test_phone_bizbrief.gd`, `docs/REFERENCE.md` §3.10 Cultivators, `CODEMAP.md`.

- [ ] Manage shows live Procurement status; the dedicated page lists current assignments per cultivator without repeating all unassigned veins.
- [ ] Assign vein opens a chooser with eligible veins; assigning a vein already held by another cultivator preserves the current move behaviour.
- [ ] Picking target step controls, unassign and assignment changes work as before.
- [ ] No-room, no-cultivator and no-vein states are distinct and concise. Focused Godot 4.7 tests pass; human checks chooser and long-roster scroll on-device.

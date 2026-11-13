# 04 — Vein panel and HQ door readouts

**What to build:** Guard management outside the Security screen becomes readouts plus deep links. The vein detail panel shows a guard row with count, "+ Assign" (from Reserve, or "No one in reserve — Hire ›" straight to the board) and "Manage ›" into the Posts tab. The HQ door Security zone keeps hardware (lock, cameras, door, alarm, ward); its guard tile becomes a count readout plus a deep link to Posts. The HQ guard kit list reads posted bodies. Without the Security Office, the vein panel and HQ door show a clear hint that guards need a Security Office, and no posting controls.

**Blocked by:** 03 — Posting and player guard-count cutover.

**Relevant files:**
- `scenes/components/vein_detail_panel.gd`, `scenes/screens/hq_door.gd`, `scenes/screens/hq_guard_kit.gd`, `scenes/screens/vein_list.gd`, `scenes/screens/map.gd`
- `systems/muscle.gd` (`can_manage`, `post`), `systems/nav.gd`, `systems/phone_nav.gd`
- Tests: `tests/test_vein_detail_panel.gd`, `tests/test_hq_door.gd`, `tests/test_hq_guard_kit.gd`
- `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Vein panel "+ Assign" posts via the same `Muscle` function as the Security screen
- [ ] Empty Reserve shows the Hire link, which opens the board
- [ ] "Manage ›" opens Security on the Posts tab
- [ ] HQ door guard tile is a readout + deep link; hardware rows unchanged
- [ ] No-room hint shown on vein panel and HQ door when the room isn't owned; no posting controls there
- [ ] PROSE-REVIEW flagged: hint and button strings
- [ ] On-device check listed: vein panel guard row, Hire link, Manage link, HQ door tile, no-room hint

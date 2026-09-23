# 06 — Harvest Light/Hard chooser in map card style

**What to build:** On the Map tab, tapping a vein and then Harvest opens the Light/Hard depth chooser inside the vein bubble. Its buttons and Back control switch from the old orange default style to the map card aesthetic already used by the bubble's round actions and the vein detail panel. Content (yield, condition before→after, disabled reasons) and behaviour are unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/vein_bubble.gd` (`_build_chooser`, `_build_chooser_row`, `_close_chooser`)
- `scenes/components/map_card_style.gd`, `scenes/components/vein_detail_panel.gd` (style reference)
- `ui.gd` shared builders (`action_button`, `style_action_button`)
- `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Light, Hard and Back render in the map card style, with dim styling when disabled
- [ ] Tapping Light/Hard still performs the harvest; Back still returns to the bubble
- [ ] check_all clean; human visual QA list in report

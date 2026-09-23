# 03 — Restyle the Map tab's old district/site/vein menus

**What to build:** The older Map tab path (tap a district → district panel → site sheet with its veins → a vein's action card) uses the same map card look as the new vein bubble and vein detail panel. That covers the paper card, ink text, action-button styling and dim states, replacing the old orange default buttons. Behaviour and actions are unchanged; this is visual only.

**Blocked by:** 02 — touches the same security/guard control; keep it working.

**Relevant files:**
- `scenes/screens/map.gd` (`_build_district_panel`, `_build_district_actions`, `_build_site_row`, `_build_buy_vein_button`, `_build_site_sheet`, `_build_faction_vein_content`, `_build_claimed_site_content`, `_build_seed_row`, `_build_vein_action_card`, `_build_prune_button`, `_build_security_row`, `_build_alarm_row`)
- `scenes/components/map_card_style.gd`, `scenes/components/vein_detail_panel.gd`, `scenes/components/vein_bubble.gd` (style references)
- `ui.gd` shared builders (`style_action_button`, bordered-panel helpers)
- `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] District panel, site sheet, faction-vein content, and player vein action card all render in the map card style
- [ ] No old default orange-style buttons remain on this path
- [ ] All existing actions (buy vein, seed, harvest, cultivate, security, alarm, raid toggle) still work
- [ ] check_all clean; human visual QA list in report

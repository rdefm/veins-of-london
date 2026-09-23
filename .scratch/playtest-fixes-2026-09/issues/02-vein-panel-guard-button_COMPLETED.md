# 02 — Guard button works in the new vein panel

**What to build:** On the Map tab, tapping a vein and using the security/guard button in the new vein detail panel buys the next security tier or "+1 Guard", exactly like the old district → site → vein menu already does.

Cause (found during triage): `_build_security_button` in the vein detail panel sets `disabled` when `upgrade["tierId"] == null`. That is exactly the uncapped "+1 Guard" state after a vein reaches `guarded`, so the button is permanently dead from then on. The old `map.gd` `_build_security_row` only checks cash.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `scenes/components/vein_detail_panel.gd` (`_build_security_button`)
- `scenes/screens/map.gd` (`_build_security_row`, working reference)
- `systems/cultivating.gd` (`next_security_upgrade`, `upgrade_vein_security`, `extra_guard_cost`)
- REFERENCE.md §"Stackable guards past guarded"

**Status:** ready-for-agent

- [ ] With enough cash, the panel's security button is enabled at every tier, including the repeatable "+1 Guard" once the vein is guarded
- [ ] Tapping it performs the purchase (tier up, or `extraGuards` +1) and the panel refreshes to show the new state
- [ ] Disabled only when cash is short
- [ ] Test covers the guarded → "+1 Guard" enabled state

# 08 — New Dial menu: Movement and Complication sections, Craft

**What to build:** Bring the Movement and Complication sections of the new Dial menu (07) to the same interaction as the Lens section: zoom in, seated component(s), scrollable side list of held components, tap → info bubble, drag/Fit loads immediately, drop on a filled socket swaps, drag off unloads. Multi-socket Complications show all sockets. Each section's side list has a **Craft** button opening the existing crafting flow for that component kind, returning to the same section afterwards. With this done, HQ Dial no longer uses DialLoadoutMenu.

**Blocked by:** 07 — New Dial menu: overview, zoom, Lens section

**Relevant files:**
- `scenes/screens/hq_dial.gd` + the new Dial menu component from 07
- `scenes/modals/craft_components_menu_modal.gd`, movement craft modal, `scenes/modals/dial_socket_modal.gd`
- `scenes/modals/dial_wind_modal.gd`
- `systems/dial.gd` (Movements, Complications incl. multi-target variant, craft)
- REFERENCE §1.4, §3.5
- tests: `tests/test_hq_dial.gd`

**Status:** ready-for-agent

- [ ] Movement + Complication sections match Lens section behaviour
- [ ] Craft button per section opens existing craft flow and returns to that section
- [ ] HQ Dial no longer builds DialLoadoutMenu (Profile/combat prep still do until 10)
- [ ] Tests cover Movement and Complication load/swap/unload
- [ ] CODEMAP updated

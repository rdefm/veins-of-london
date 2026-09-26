# 03 — Assign a vein to a cultivator from the vein bubble

**What to build:** The player-vein tap bubble on the Map gets a cultivator action.

- The button only appears when at least one contact currently holds the Cultivation role. Owen while swapped to Production doesn't count and isn't listed.
- **Unassigned vein:** the button reads e.g. "Assign cultivator". Tapping it opens a list of current cultivators. Each row shows the cultivator's name and how many veins they already tend. Picking one assigns the vein with default settings (default target, via the existing assign-vein system call, which also moves it off any other list).
- **Assigned vein:** the button names the cultivator (e.g. "Tended by Owen") and reopens the picker. There the current cultivator is marked and an Unassign option drops the vein from their list. A second control lets the player adjust that vein's hold target directly in the bubble (stepper, e.g. 70 → 60), through the existing per-vein target system call.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/vein_bubble.gd`, `scenes/components/map_card_style.gd` (option rows, stepper), `scenes/screens/map.gd`, `systems/rooms.gd` (`assign_vein`, `unassign_vein`, per-vein targets, cultivator lists), `systems/contacts.gd` (role holders), `tests/test_rooms.gd`, REFERENCE.md §3.10 "Staff roles" (Cultivator veins) and "Cultivator (per block, hold-at-target)".

**Status:** ready-for-agent

- [ ] The button is hidden when no contact holds Cultivation, and shown otherwise, for player-owned veins only.
- [ ] Picker rows = current Cultivation-role holders with vein counts. The current cultivator is marked. Unassign is present when assigned.
- [ ] Picking assigns with the default target. Re-picking moves the vein between cultivators with its target kept (existing rule).
- [ ] Once assigned, the target is adjustable in the bubble, and the value matches BizBrief Procurement.
- [ ] The screen never mutates `cultivatorVeins` / `veinStationTargets` directly. If a needed system helper doesn't exist (e.g. "list current cultivators with counts"), add it to `rooms.gd` with tests.
- [ ] On-device QA block: button visibility, picker, unassign, target stepper.

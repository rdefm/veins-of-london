# 03 — HQ Guard Kit screen

**What to build:** An HQ screen lists every player vein with 1+ guards or a non-empty kit, showing its kit, slots used/capacity and idle state. Tapping a row opens that vein's stocking sheet. It's reached from the HQ security zone next to the guard tile. The ticket confirms the exact entry point and reports it.

**Blocked by:** 02 — Vein detail row + stocking sheet.

**Relevant files:** `scenes/screens/hq_door.gd` (guard tile, `PhoneNav.open_guard_costs()` precedent near line 80), PhoneNav, the guard costs screen (sibling-screen pattern), `systems/guard_kit.gd`, `CODEMAP.md`. Spec §UI.

**Status:** ready-for-agent

- [ ] The screen lists guarded veins and veins with a non-empty kit, and hides veins that have neither.
- [ ] Each row shows the kit summary, `n/cap` and idle state. Tapping opens the stocking sheet for that vein, and the list refreshes after confirming.
- [ ] Entry point from the HQ security zone. New strings flagged PROSE-REVIEW, plus an on-device check block.

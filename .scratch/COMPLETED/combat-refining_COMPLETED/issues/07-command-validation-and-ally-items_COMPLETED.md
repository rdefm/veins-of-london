# 07 — Command validation against selection + ally-targeted items

**What to build:** Commands respect the current selection. With the player or an ally selected, Attack is unavailable (disabled row; a press does nothing, spends nothing, advances nothing) — it never silently hits another enemy. Leg it and other untargeted commands stay available regardless of selection. Item opens the existing Bag flow; each item/Complication's availability there follows ticket 01's ally-targetable table against the current selection — Healing Burst used with an ally selected heals that ally only, never the player; self-only items remain self-only; AoE items ignore selection as today. Invalid uses return a reason and leave state, inventory and the queue untouched.

**Blocked by:** 01 — Canonical contract amendments; 05 — Tap selection.

**Relevant files:**
- `systems/combat.gd` — `player_attack` (selection guard), `use_blast`, `use_black_hole`, `cast_complication` (single-target vs AoE branch), new validity query for the dock
- `systems/consumables.gd` — `use_healing_burst` gains a target argument per 01's table
- `scenes/components/bag_drawer.gd` — `_add_combat_use_buttons`, `_on_use_healing_burst`, `_play_result_beats`
- `scenes/components/combat_command_dock.gd` — `_build_action_deck` (Attack/Item disabled state from the validity query), `configure`
- `scenes/screens/combat.gd` — `_sync_footer`, `_on_attack_pressed`
- `tests/test_combat.gd` — attack-with-ally-selected, ally heal, self-only rejection, AoE unchanged
- `tests/test_combat_screen.gd` — "item_card_is_disabled_when_the_player_has_nothing_usable…", attack-row disabled cases
- `docs/REFERENCE.md` — §3.7 Use Healing Burst, §3.7a Targeting, ally-targetable table (as amended by 01)

**Status:** ready-for-agent

- [ ] Ally selected + Attack pressed: no beats, no snapshot, no XP, no HP change on any enemy; the row renders disabled
- [ ] Ally selected + Leg it: flee resolves exactly as with an enemy selected
- [ ] Ally selected + Healing Burst: ally HP rises by the canonical amount, player HP unchanged, one item consumed, beat/log names the ally
- [ ] Ally selected + a self-only effect from 01's table: rejected with a reason, nothing consumed
- [ ] Enemy selected: Attack, Blast and single-target Complications behave exactly as before
- [ ] Black Hole / AoE ignores selection and hits every living enemy as before
- [ ] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP rows updated

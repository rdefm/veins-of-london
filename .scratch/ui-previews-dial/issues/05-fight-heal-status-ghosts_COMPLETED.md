# 05 — Fight: heal and status preview ghosts

**What to build:** Extend the preview projection to non-damage effects. An armed heal (salve/burst/ally heal etc.) shows a **green** glowing ghost extending the target's HP fill. An armed status effect (stun, Powder, Shield, Pan statuses, Dial Complication effects…) shows a faded/pulsing **ghost chip** on the target's status icon row. Multi-target units ghost every target. Visible incoming heals/statuses from others use the same visuals.

**Blocked by:** 03 — Fight: outgoing damage preview ghost

**Relevant files:**
- `systems/combat_rounds.gd` (`status_icons`, `_ally_heal_patient`, `_apply_pan_status`, kit item resolution, the 03 projection)
- `scenes/components/status_icon_row.gd`
- `scenes/components/combat_stage.gd`
- `data/combat_visuals.json` (`statusIcons`, ghost colours)
- REFERENCE §3.7b Table 4, Table 5
- tests: `tests/test_combat_rounds.gd`

**Status:** ready-for-agent

- [ ] Armed heal shows green ghost on target bar, capped at max HP
- [ ] Armed status shows ghost chip on target's status row
- [ ] Multi-target units ghost every target
- [ ] Projection stays pure; tests cover heal cap and a status preview

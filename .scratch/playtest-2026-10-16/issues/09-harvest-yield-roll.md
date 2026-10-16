# 09 — Harvest yield roll

**What to build:** Harvest (prune) yield becomes a roll like cultivating: uniform between ×0.8 and ×1.2 of today's computed yield (today's value becomes the midpoint; average unchanged). Multipliers live in `vein_growth.json`. The harvest chooser shows "Yield min–max" instead of a single number. All callers of the yield function (player, staff, faction) roll.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/cultivating.gd` (`prune_yield`, `prune`), `data/vein_growth.json`, `scenes/components/vein_bubble.gd`, `systems/station_bubble.gd`, `scenes/screens/map.gd`, `systems/rooms.gd`, `systems/faction_sim.gd`, `docs/REFERENCE.md` §3.4 Cultivating & pruning

**Status:** ready-for-agent

- [ ] Yield min/max helpers exposed (for the UI and ticket 10)
- [ ] Roll uses the seeded `Rng` so Rewind/tests stay deterministic
- [ ] Chooser displays min–max
- [ ] REFERENCE.md §3.4 updated with the roll
- [ ] Tests cover range bounds and preview

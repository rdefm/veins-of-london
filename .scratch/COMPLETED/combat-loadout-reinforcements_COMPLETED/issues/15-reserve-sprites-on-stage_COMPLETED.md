# 15 — Reserve fighters on the combat stage

**What to build:** The stage shows up to three waiting fighters per side as much smaller, more distant sprites in queue order, followed by `+N` for more. When one joins, it leaves the background queue and takes the active place; the count and projected turns refresh without unexpectedly changing the player's selection. Active fighters stay legible at the 390 × 844 portrait viewport.

**Blocked by:** 13

**Relevant files:** `scenes/components/combat_stage.gd`, `data/combat_visuals.json`, `scenes/screens/combat.gd`, `scenes/components/combat_director.gd`, `tests/test_combat_screen.gd`, `docs/ui-vision.md`, `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] Up to three reserve sprites per side, then `+N` (scene test)
- [ ] Entry moves the sprite into the active place and updates `+N`
- [ ] Player selection unchanged by an entry unless the selected target was KO'd
- [ ] On-device QA block: depth read, legibility, queue readability

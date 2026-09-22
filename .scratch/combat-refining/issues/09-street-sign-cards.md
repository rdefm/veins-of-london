# 09 — Street-sign card restyle + damage overlays

**What to build:** Occurrence cards read as clean London street signs: light ground, dark readable lettering, a restrained border, with the faction colour kept for the HP bar and faction line (canonical mapping unchanged — real colour for raids, UNKNOWN grey for muggings/defend/home raid). As a combatant's HP falls the card becomes more battered at the existing 60% / 30% tiers (crack lines, chipped corner, slight tilt at ruined), without ever covering name, HP bar, statuses or intent. Long canonical names, status lists and intent text stay readable in both collapsed and expanded cards without spilling onto the Dial. The card identity is deliberately distinct from the command rows.

Decal artwork may be authored as a small overlay set under assets; if the human supplies none, draw the tiers procedurally with the same thresholds.

**Blocked by:** 04 — Occurrence queue cards.

**Relevant files:**
- `scenes/components/turn_order_strip.gd` — `NameplateCard._draw`, `_build_card_content`, `CARD_HEIGHT`, `MAX_CARD_WIDTH`, `CRACKED_HP_FRACTION`, `RUINED_HP_FRACTION`, `RUINED_TILT_DEGREES`, `PULSE_HP_FRACTION`, `NEUTRAL_COLOUR`, `UNKNOWN_COLOUR`, `_enemy_faction_display`
- `data/palette.json` — sign ground/lettering/border tokens
- `data/factions.json` — `colour` (read only)
- `assets/` — optional decal overlay set
- `tests/test_turn_order_strip.gd` — damage-tier, pulse, faction-colour and readability cases
- `docs/combat-animation-vision.md` — §2.4 Nameplate anatomy, Damage-decal tiers, Faction-colour mapping
- `docs/ui-vision.md` — §6 Colour rules, §7 Typography

**Status:** complete

- [x] Card background is a light sign colour with dark text; border is thin and neutral, faction colour appears only on the HP bar and faction line
- [x] Damage tier boundaries remain exactly 60% and 30% of hpMax; pulse remains at 20%
- [x] At the ruined tier the name, HP bar and faction line are still fully drawn inside the card rect (no overlay covers them)
- [x] A 24-character name, three status lines and a long intent string fit the expanded card via wrap/ellipsis without exceeding the reserved band
- [x] Faction-colour mapping tests pass unchanged
- [x] Colours come from `palette.json`/constants, not inline literals
- [x] `scripts/check_all.sh` and `scripts/run_tests.sh` pass; CODEMAP row updated
- [x] Report lists on-device checks: sign legibility, overlay restraint, distinctness from command rows

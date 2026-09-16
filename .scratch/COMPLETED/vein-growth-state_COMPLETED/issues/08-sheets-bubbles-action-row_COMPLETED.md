# 08 — Sheets, bubbles, action row

**What to build:** every place the player interacts with a single vein directly (the map's site/vein sheet, the station tap bubble, the action row) drops `charged`/level branching for growth bar + band label + days-to-wall + projected prune yield, with a distinct always-visible treatment for a collapsed (spent) vein.

**Blocked by:** 01 (needs `growth`, `growth_band`, `prune_yield`, `days_to_wall`).

**Status:** ready-for-agent

- [ ] `scenes/screens/map.gd`'s site/vein sheet, `systems/station_bubble.gd`'s option list, and `scenes/components/ui.gd`'s action row all rewritten: growth bar + band label + days-to-wall + projected prune yield; actions Cultivate / Prune (light) / Prune (hard) / Upgrade security / Alarm.
- [ ] Prune buttons always shown but disabled with the reason surfaced when projected yield is 0 (at or below neutral) — player sees *why*, not just a missing button.
- [ ] `station_bubble.gd`'s option list branches on projected yield, not `charged`.
- [ ] Collapsed band (growth 0) gets explicit treatment everywhere it appears (sheet, bubble, and — once ticket 09 lands — the vein list): states plainly the vein is spent and may be lost any day, foregrounds Cultivate as the rescue. Must never be visually confused with a vein that's merely doing badly.
- [ ] `docs/M1-LONDON.md` D4 site/vein sheet line updated (currently lists "level, dev bar, charge state" — all three deleted).
- [ ] `test_map_screen.gd`, `test_station_bubble.gd` updated/added.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.

**Human to check on-device:** projected prune-yield numbers look sane before pressing; disabled-prune reason text reads clearly; collapsed-vein treatment is unmistakable in both the sheet and the bubble.

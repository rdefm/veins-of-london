# 06 — Home raid: turn-order cards jitter sideways

**What to build:** In the home raid fight, the combat cards at the top of the screen (the turn-order strip) sometimes shift left and right when they should hold still. This seems specific to this fight. Find the cause, for example the roster count changing, reflowing widths or a tween fighting a re-sync, and fix it so the strip only moves when the turn order really advances.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/turn_order_strip.gd`, `scenes/components/combat_stage.gd`, `scenes/screens/combat_rounds.gd`, `data/combat_rounds.json` (home raid fight), `data/events/home_raid_intro.json`, `systems/combat_prep.gd`, `systems/home.gd`.

**Status:** ready-for-agent

- [ ] Root cause written in the ticket report
- [ ] Cards hold position between turn advances in the home raid
- [ ] A regression test (headless) pins the cause, where it's testable
- [ ] Other fights' strips unchanged

On-device check: play the home raid through several rounds and watch the strip.

# 10 — Diagnose: vein card off the top of the map; reclaimed vein won't cultivate

**What to build:** A diagnosis with a written report, not a fix. Two symptoms seen on device:

1. **Card off-screen.** Tapping any vein near the top of the map (seen at Hampstead) opens the vein bubble above the pin. The bubble's top runs under the top bar and off-screen, so its title row ("Hampstead · Life Orichalchum ›") can't be tapped and the full vein panel can't be opened. Screenshot: `.scratch/playtest-prologue-hq-2/vein-card-off-top.png`.
2. **Reclaimed vein won't cultivate.** The vein was raided off the player, and the player raided it back. On that vein only:
   - Cultivate plays no animation, and the condition bar doesn't move.
   - After repeated cultivates, BizBrief says the vein is about to collapse.
   
   Other veins cultivate normally.

Reproduce both headless where possible: debug-start state, take a vein by faction raid, take it back by player raid, then cultivate. Find the root causes and write them up in a `## Comments` section on this ticket. Propose one fix ticket per root cause (title, what to build, acceptance criteria), and don't create them until the human approves.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/vein_bubble.gd` (pin-anchored placement), `scenes/components/map_canvas.gd` (bubble anchoring, `vein_cultivated` ring tween), `scenes/components/top_bar.gd`, `systems/cultivating.gd` (cultivate, growth, collapse), `systems/raiding.gd` (player raid reclaim), `systems/faction_ai.gd` (faction raid on a player vein), `systems/rooms.gd` (`cultivatorVeins`, targets), `systems/business_stats.gd`, `tests/test_raiding.gd`; REFERENCE.md §3.12 Vein raiding.

**Status:** ready-for-agent

- [ ] Root cause for the off-screen card, with the condition that triggers it
- [ ] Reproduction (headless test or script) of the reclaimed-vein cultivate failure, or a clear note of why it can't be reproduced
- [ ] Root cause for the missing animation, the frozen bar, and the collapse warning (one cause or several)
- [ ] Proposed fix tickets written in the report; no code fixes in this ticket

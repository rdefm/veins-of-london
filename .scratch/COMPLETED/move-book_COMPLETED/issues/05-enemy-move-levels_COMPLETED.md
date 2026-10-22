# 05 — Long-press an enemy to see its move levels

**Visual spec:** `.scratch/move-book/move-book.html` (live copy: https://claude.ai/artifact/FPL7F27VL6oHT5DTsSYgFR), placement "4 · In the fight · Enemy long-press" and Decisions item 3. If this ticket and the mock disagree, stop and ask.

**What to build:** In a fight, holding an enemy shows its name, Combat level and its five move levels.
- A move's level shows **"?"** unless the enemy has a **read** planned action of that move this round (same fog roll as the turn-order strip), or has **used** the move this fight.
- Once the enemy has used a move, its true level stays shown for the rest of the fight.
- Enemies roll move levels per fight, so nothing carries between fights.
- The used-moves record lives inside the fight state (plain data), so Rewind rolls it back with the fight.
- Allies show their true levels.

**Blocked by:** 02 — Move Book in the Profile app (shared badge/peek styling).

**Relevant files:**
- `systems/combat_rounds.gd` (fog / `fogRngState`, action resolution, combatant build, Rewind frames)
- `scenes/components/combat_stage.gd` (tap-to-target), `scenes/components/turn_order_strip.gd` (`actionUnread` "?" styling)
- `scenes/screens/combat_rounds.gd`
- `tests/test_combat_rounds.gd`
- `CODEMAP.md`; REFERENCE §2 (state paths), §3.7b Fog, Move levels

**Status:** ready-for-agent

- [ ] Read-only helper returns each enemy move as level or unknown, per the rule above (tests: unread → ?, read → level, used → level stays after replanning)
- [ ] Rewind past a first use hides that level again (test)
- [ ] Long-press on an enemy shows the panel; tap still targets
- [ ] REFERENCE §2/§3.7b updated
- [ ] Human check: "?" vs level legibility; panel doesn't block targeting

# 135 — Diagnose: combat-log lines in the ticker long after a fight

**What to build:** The top-bar ticker scrolled combat-log lines ("YOU ATTACK - 3 DAMAGE. ENEMY: 2/29 HP.") while the player was on the Map, with no fight for a long while (seen at DAY 27 EVENING). Find out why combat lines survive or surface outside combat. Candidates: held while combat was active then released later; saved in notification state and restored on load; pushed by some non-combat path. Fix it so combat-log lines only ever show while that fight is running, and get dropped when it ends. Use the diagnosing-bugs loop; write a failing test first.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/top_bar.gd` (combat-hold routing ~L115/L150), `scenes/components/notification_ticker.gd`, `systems/notify.gd` (`META_COMBAT_LOG`), `scenes/screens/combat.gd` (~L339 push), `autoload/SaveManager.gd` (whether notifications are saved); ui-vision.md §5.

**Status:** ready-for-agent

## Root cause

Not a late push: `combat.active` only goes false at `Combat` teardown, after every beat has posted its line. Two presentation-side leaks:

1. **Ticker never lets go.** `NotificationTicker` keeps its last message on the board indefinitely, re-running the marquee when it overflows (the log line does). Nothing removed combat lines when the fight ended, so the final combat line — plus any still queued — kept scrolling on the Map until some unrelated notification arrived. Held (non-combat) messages were only appended behind them.
2. **Reset path ignored the flag outside combat.** Combat lines live in the saved `notifications` list; on boot/load/Rewind outside combat `_latest_eligible_text` returned the newest entry regardless of `combatLog`, so a save made right after a fight showed a combat line.

Fix: ticker entries carry a `transient` flag; TopBar enqueues combat lines as transient and calls `drop_transient()` on the combat→not-combat edge (next queued message or latest non-combat notification replaces the board with no animation). Reset path outside combat picks only non-combat entries; a combat-log push outside combat is ignored.

- [x] Root cause written up in this ticket before fixing
- [ ] Regression test reproduces it, then passes
- [ ] After combat ends, no combat-log line reaches the ticker
- [ ] Human on-device: finish a fight, go to the Map, pass time — the ticker shows no combat lines

# 135 — Diagnose: combat-log lines in the ticker long after a fight

**What to build:** The top-bar ticker scrolled combat-log lines ("YOU ATTACK - 3 DAMAGE. ENEMY: 2/29 HP.") while the player was on the Map, with no fight for a long while (seen at DAY 27 EVENING). Find out why combat lines survive or surface outside combat. Candidates: held while combat was active then released later; saved in notification state and restored on load; pushed by some non-combat path. Fix it so combat-log lines only ever show while that fight is running, and get dropped when it ends. Use the diagnosing-bugs loop; write a failing test first.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/top_bar.gd` (combat-hold routing ~L115/L150), `scenes/components/notification_ticker.gd`, `systems/notify.gd` (`META_COMBAT_LOG`), `scenes/screens/combat.gd` (~L339 push), `autoload/SaveManager.gd` (whether notifications are saved); ui-vision.md §5.

**Status:** ready-for-agent

- [ ] Root cause written up in this ticket before fixing
- [ ] Regression test reproduces it, then passes
- [ ] After combat ends, no combat-log line reaches the ticker
- [ ] Human on-device: finish a fight, go to the Map, pass time — the ticker shows no combat lines

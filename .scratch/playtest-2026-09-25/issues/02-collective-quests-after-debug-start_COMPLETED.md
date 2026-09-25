# 02 — Diagnose + fix: collective quests don't fire after debug start

**What to build:** After Debug Start, the collective questline can't be triggered. Diagnose the cause and fix it so collective quests fire normally from a debug-start state. Leading hypothesis: Debug Start flips every boolean flag to `true`, so collective questline beats read as already done/seen and their triggers never pass. Fix Debug Start so questline progression flags stay at "not started" while everything else it unlocks stays unlocked.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/debug_start.gd` (flag loop in `apply()`), `systems/collective.gd` (`maybe_trigger_*`), `systems/events.gd`, `tests/test_col_a1_*.gd`, `tests/test_playthrough.gd`; REFERENCE §5 (Debug Start), §2 (flags).

**Status:** ready-for-agent

## Root cause

Two parts, both in `DebugStart.apply()`:

1. **The first beat is never delivered.** `col_a1_intro` reaches the player only as an Archie `pendingMessages` entry queued by `archie_cultivation`'s `on_complete` (the cultivating tutorial). Debug Start's flag loop marks `cultivationTutorialSeen = true`, so that event never plays, nothing queues `col_a1_intro`, and Archie's card has no Continue button. None of the `colA1*` flags are in the default flag dict (they're set lazily by events), so the loop doesn't touch them — the blocker is the missing delivery, not a flipped A1 flag.
2. **Act 2 would be pre-finished.** The loop flips the `colA2*` progression flags present in defaults (`colA2HakimIntelBought`, `colA2HakimRetaken`, `colA2SpineReward`, `colA2Complete`) to `true`, so even after Act 1 the spine reward/closer gates read as already done.

Fix: questline progression flags (`colA*` prefix) stay at default `false`; Debug Start queues the same `col_a1_intro` pending entry `archie_cultivation` would have (read from that event's data). Unlock flags (`collectiveLaneUnlocked`, `dialGiftGranted`, etc.) stay `true`.

- [x] Root cause confirmed and written up in this ticket before fixing
- [x] After Debug Start, the first collective beat triggers under its normal conditions
- [x] Debug Start still unlocks every screen/feature it did before
- [x] Regression test: Debug Start state → collective trigger fires
- [x] REFERENCE §5 updated if Debug Start's flag rule changes

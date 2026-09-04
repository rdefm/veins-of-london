# 112 — Gate Archie/James job offers behind per-contact intro flags

**What to build:** `Jobs.roll_daily_offer()` and `ArchieDeals.roll_daily_offer()`
(both called unconditionally from `TimeSystem.daily_tick()`) currently have no
tutorial-progress gate — only their own "already active" flag blocks
re-rolling — so both James and Archie can push a job/deal offer (including a
Notify/SMS naming them) before the story has properly introduced that
mechanic. Add:

- `Jobs.roll_daily_offer()`: early-return unless `flags["jamesMotionEventSeen"]`
  is true — matching the flag `ContactCards.build_james_card()` already uses
  to gate James's job-offer UI card, and the intent `jobs.gd`'s own header
  comment already documents but never wired into the roll.
- `ArchieDeals.roll_daily_offer()`: early-return unless
  `flags["archieMotionEventSeen"]` is true — Archie's own parallel
  introduction beat (`data/events/archie_motion.json`, mirroring
  `data/events/james_motion.json` for James), currently ungated anywhere.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] James's daily job-offer roll never fires before `flags.jamesMotionEventSeen`
      is true, verified by a test.
- [ ] Archie's daily tag-along-deal roll never fires before
      `flags.archieMotionEventSeen` is true, verified by a test.
- [ ] Once each flag is true, the existing offer behavior (chance curves,
      "already active" guard) is unchanged.
- [ ] A fresh-game/early-tutorial playthrough test (or an extension of
      `tests/test_playthrough.gd`) confirms neither offer appears before its
      gating beat has played.

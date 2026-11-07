# 01 — Import → Promote round trip is lossless

**What to build:** Opening any live event in the storyboard tool and promoting it unedited must leave its meaning unchanged. This is the safety net for everything else in this folder: if the round trip loses data, no later edit can be trusted.

Add a corpus test across every live event: import to a branch draft, promote, then compare with the live file. Card order may differ where the flat layout changes, so compare meaning: every card, option, effect, condition, top-level field, and where each route ends up. Fix each loss found. An event that's deliberately not round-trippable needs a named exception with a reason.

**Blocked by:** None — can start immediately.

**Relevant files:** `tools/storyboard.html` (Draft model section: import, `promoteDraft`, `promoteForWrite`, `serialiseEvent`), `tools/promote_storyboard.js`, `tools/test_storyboard.js`, `data/events/`, `.scratch/COMPLETED/storyboard-editor_COMPLETED/spec.md` § Draft format

**Status:** ready-for-agent

- [ ] `node tools/test_storyboard.js` round-trips every file in `data/events/`
- [ ] Top-level event fields survive (`deck`, `pin`, `at`, `repeatable`, `observations`, `fightPresets`, `fillFromContext`, `reinforceClock`, `on_complete`)
- [ ] Every card, option, effect and image survives
- [ ] Each route reaches the same destination after any reordering
- [ ] Any exception is named with a reason
- [ ] No new failures in `test_storyboard.js`

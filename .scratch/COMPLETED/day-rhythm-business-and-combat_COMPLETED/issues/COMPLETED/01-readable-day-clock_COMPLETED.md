# 01 — Readable day clock

**What to build:** Players can read the current day, phase and remaining daily actions at a glance.

**Blocked by:** None — can start immediately.

**Status:** signed off

- [x] Show full Morning, Afternoon or Evening and the day number persistently, including after save/load.
- [x] Show a persistent sun/moon cue and three segments distinguishing completed, current and remaining phases without colour alone.
- [x] Label time-consuming actions when they use the final daily block; free or unavailable actions must not imply a time cost.
- [x] Preserve the three-block rules, existing time costs and automatic rollover.
- [x] Verify public action/render boundaries for each phase and final-block labels; request device QA at 390px portrait and relevant safe areas.

## Delivery constraints

Follow the parent feature spec and current canonical mechanics. Keep content/tuning in data, gameplay state serializable, mutations in systems and presentation outside them. Update canonical/domain/ownership documentation when responsibilities or approved mechanics change. After every GDScript edit run the required autoload-aware syntax check, then the full headless suite before completion; report device-only checks separately and flag new prose with PROSE-REVIEW.


## Implementation — 2026-09-13

Full phase/day and sun/moon on the departure board; check/current-square/hollow-square progress markers and cash on the second row. Existing safe-area clearance now reserves 80px for both status rows and two notifications. Labels cover Prospect, Seed, Cultivate, both Prune depths, Raid, Train, James flat-pay work, experiment/refine and the time-consuming event choice. Rest identifies next morning. No mechanics or persistent state changed.

PROSE-REVIEW: `data/constants.json` (`dayClock`).

Device QA (390px portrait and notched device): full phase/day/cash visible; markers distinct without colour; bag and notifications clear of content; Evening labels readable on map/list/Train/jobs/event/bench; free/blocked actions unlabelled; Rest/experiment captions visible over art; Morning restored correctly after rollover and load.

Signed off — 2026-09-19: user confirmed device QA and accepted the pre-existing repository-wide failures noted in `verification-01.md` (repaired separately under ticket 03's cleanup) as out of scope for this ticket.

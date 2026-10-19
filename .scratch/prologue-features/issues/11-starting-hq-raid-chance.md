# 11 — Starting HQ raid chance

**What to build:** The starting home (bedsit) is noticeably riskier, so Archie's "this place is a liability" rings true and moving feels needed. Raise the bedsit's raid base chance, and widen the gap to the next tiers if needed, as a data change. Placeholder values, flagged for balance sign-off. Source: `docs/story-restructure.md` "Features to build" item 5.

**Blocked by:** None — can start immediately.

**Relevant files:** property tier data (`raidBaseChance`), `systems/home.gd` (`get_home_raid_chance` L25, `get_raid_chance_for_tier` L31, `roll_daily_raid` L48). REFERENCE §1 property table, §3.3 Home.

**Status:** ready-for-agent

- [ ] The bedsit's `raidBaseChance` is raised (placeholder) and REFERENCE §1 is updated with "needs balance sign-off".
- [ ] The Prologue's scripted flat raid is unaffected (it's event-driven, not rolled).
- [ ] Existing raid tests are updated. A test asserts bedsit > studio > flat.

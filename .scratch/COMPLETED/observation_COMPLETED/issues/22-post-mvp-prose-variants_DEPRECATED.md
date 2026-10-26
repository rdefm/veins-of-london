# 22 — Prose variants per block/tier

**Phase:** Post-MVP

**What to build:** Support `variants` on observation blocks/tiers so repeat reads don't read identically. Selection rule to be decided by the human.

**Blocked by:** MVP playtest sign-off by the human — **APPROVED by the human**.

**Relevant files:** `systems/observation.gd`, `tests/test_observation.gd`, `tests/test_event_content_lint.gd`; REFERENCE.md Observation §.

**Status:** wontfix

- [ ] Variant selection stable-seeded (replays on reload)
- [ ] Lint validates variants

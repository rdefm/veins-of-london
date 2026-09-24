# 04 — Diagnose: end-of-time-block animation stops playing

**What to build:** After playing a while, the end-of-time-block transition animation stops showing when a block passes. Diagnose first (diagnosing-bugs loop), then fix. No known repro pattern. Leading suspect: the transition's "outcome finished" gate or session sync gets stuck on leftover event/combat state, or a captured transition is never cleared so later ones are dropped. Temporary logging fine while diagnosing; remove before commit.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/time_transition.gd`, `scenes/components/time_transition.gd`, `autoload/EventBus.gd` (`time_advanced`), `systems/time_system.gd`, `systems/events.gd`, `systems/combat.gd`.

**Status:** ready-for-agent

- [ ] Root cause identified and written up under `## Comments`
- [ ] Headless repro test that fails before the fix, passes after
- [ ] Animation plays on every block advance across event/combat/rest/day-rollover paths

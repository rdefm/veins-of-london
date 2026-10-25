# 08 — Tier effects + observation memory

**Phase:** MVP

**What to build:** A read can have consequences and be remembered. Per-tier `effects` run once, when that tier is first reached (an improvement runs only newly reached tiers' effects). On event completion the best tier per ore per observation is written to a persistent record keyed by event id + observation id (pure data, saved, survives Rewind). `observed` with `event` reads that memory, so a read in one event can unlock or boost content in a later one.

**Blocked by:** 04.

**Relevant files:** `systems/observation.gd`, `systems/events.gd` (event completion, effects runner, `condition_met`), `tests/test_observation.gd`, `tests/test_event_content_lint.gd`; REFERENCE.md §2 STATE SCHEMA, Observation §.

**Status:** ready-for-agent

- [ ] Tier effects fire once on first reaching a tier; re-reads/reopens don't re-fire
- [ ] Improvement via re-roll fires only the newly reached tiers' effects
- [ ] Memory written on completion, best tier per ore, pure data, in save
- [ ] Memory survives Rewind
- [ ] `observed` with `event` reads memory; without reads current run
- [ ] Lint validates `event` refs where resolvable

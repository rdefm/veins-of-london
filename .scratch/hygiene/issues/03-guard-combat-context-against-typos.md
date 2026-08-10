# 03 — Guard combat context against typos

**What to build:** Combat's `context` field (`"raid"`, `"mugging"`, `"event_mugging"`,
`"home_raid"`, `"event_raid"`) is currently a bare string, written as a literal at every
call site across `systems/combat.gd`, `systems/events.gd`, and several test files, with
no typo-guard — an unrecognized value silently falls through to `exit_combat()`'s
default fallback behavior instead of failing loudly. Add:

- Named string constants for the canonical context vocabulary (e.g.
  `Combat.CONTEXT_RAID`, `Combat.CONTEXT_MUGGING`, `Combat.CONTEXT_EVENT_MUGGING`,
  `Combat.CONTEXT_HOME_RAID`, `Combat.CONTEXT_EVENT_RAID`), used at existing call sites
  in `combat.gd`/`events.gd` in place of the current literals.
- A runtime check in `_start_combat()` (or wherever combat is initialized) that the
  incoming context is one of the canonical set, `push_error`-ing on an unrecognized
  value rather than silently starting combat with a context `exit_combat()` will
  mis-route.

The stored value in `state.combat.context` must remain a plain `String` — this repo's
architecture (CLAUDE.md) requires `GameState.state` stay pure Dictionaries/
Arrays/primitives, no object references. This ticket is call-site and validation
hygiene only, not a new type. There's existing precedent for canonical-array-backed
string validation in this codebase: `GameData.CANONICAL_ORE_TYPES` and
`GameData.VEIN_SECURITY_ORDER`.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Named constants exist for every current combat context value, defined once (e.g.
      on `Combat`)
- [ ] `systems/combat.gd` and `systems/events.gd` reference the constants instead of
      literal context strings at every call site that starts combat or checks
      `combat.context`
- [ ] A canonical set/array of valid contexts exists (mirroring
      `GameData.CANONICAL_ORE_TYPES`'s shape) and `_start_combat()` (or the earliest
      point a context is accepted) validates against it, `push_error`-ing loudly on an
      unrecognized value instead of silently proceeding
- [ ] `state.combat.context` is still a plain `String` in every test and save/load
      path — no object/Resource type introduced into `GameState.state`
- [ ] Tests cover: starting combat with each canonical context still behaves exactly as
      before; starting combat with an unrecognized context produces a loud error
      instead of silent default-fallback routing
- [ ] Existing combat/event tests (`tests/test_combat.gd`, `tests/test_events.gd`)
      continue to pass, updated only to use the new constants where they currently
      spell out literal context strings
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every
      touched file; `scripts/run_tests.sh` passes

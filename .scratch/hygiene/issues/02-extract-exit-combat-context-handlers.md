# 02 — Extract per-context exit handlers in Combat.exit_combat()

**What to build:** `systems/combat.gd`'s `exit_combat()` currently reads as a growing
`if context == "X": ...; return {...}` cascade (mugging-win, `event_mugging`,
`home_raid`, `event_raid`, then a generic `raid`/else fallback). Extract each branch's
body into its own private helper (e.g. `_exit_mugging_win()`, `_exit_event_mugging()`,
`_exit_home_raid(outcome)`, `_exit_event_raid(outcome)`, `_exit_default(outcome,
context)`), so `exit_combat()` itself becomes a short dispatch — teardown the shared
combat state, then call the one matching helper and return its result. Pure
refactor: no behavioral change, no new context, no new routing.

A full table-driven redesign (context string → data-only routing spec) was considered
in 7-vein-raiding ticket 02 and explicitly deferred: `home_raid` and `event_mugging`/
`event_raid` have real side effects beyond a screen redirect (starting a different
follow-up event depending on outcome, applying home-raid ore loss, checking
`state.event`) that a pure lookup table can't express without becoming a hybrid
table+code split — arguably harder to read than the current linear function. Don't
attempt that redesign as part of this ticket; if it's worth doing at all, it's a
separate, larger design decision.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] Each of `exit_combat()`'s current context branches (mugging-win, `event_mugging`,
      `home_raid`, `event_raid`, generic fallback) lives in its own named private
      helper function
- [ ] `exit_combat()` itself is reduced to: tear down `state.combat`, autosave, then
      dispatch to the one matching helper and return its `{ "nextScreen": ... }` result
- [ ] No behavioral change: every existing `exit_combat`-related test
      (`tests/test_combat.gd`, plus the `event_raid` cases added in 7-vein-raiding
      ticket 02) passes unmodified
- [ ] `godot --headless -s scripts/check_runner.gd -- systems/combat.gd` clean;
      `scripts/run_tests.sh` passes

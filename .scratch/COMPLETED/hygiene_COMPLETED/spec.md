# Spec — Codebase hygiene backlog

**Status:** Draft, from a `/code-review` pass on 7-vein-raiding ticket 02 (2026-08-10).

## Why

Standards review of 7-vein-raiding ticket 02 (`systems/raiding.gd`, `systems/combat.gd`,
`systems/events.gd`) surfaced three baseline code smells (Fowler, *Refactoring* ch. 3).
None were hard violations of a documented standard, and none were required to land
ticket 02 — CLAUDE.md is explicit that a task shouldn't carry speculative refactors of
unrelated, already-shipped code. This tracker exists so they aren't lost, and can be
picked up independently, on their own schedule, without being riders on a feature
ticket.

None of these tickets are blocked by, or block, any `7-vein-raiding` ticket. They're
general codebase hygiene, not feature work.

## Tickets

- **01** — Dedupe the XP/level-up award loop (4 copies: Crafting, Cultivating, Devices,
  Raiding).
- **02** — Extract per-context exit handlers in `Combat.exit_combat()`.
- **03** — Guard combat `context` against typos (named constants + runtime validation).

## Explicitly out of scope

- Any change to `state` shape or to the DATA→STATE→SYSTEMS→SCREENS one-way flow.
- Introducing object/Resource types into `GameState.state` — it must stay pure
  Dictionaries/Arrays/primitives (CLAUDE.md, non-negotiable).
- A full table-driven redesign of `exit_combat()` — evaluated and explicitly left as a
  "nice to have, not a requirement" in ticket 02, since several contexts (home_raid,
  event_mugging, event_raid) have real side effects beyond a screen redirect that a
  pure lookup table can't express cleanly.

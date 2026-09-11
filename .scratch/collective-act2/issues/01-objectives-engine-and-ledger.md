# 01 — Objectives engine extensions + Collective ledger

**What to build:** Three new `Objectives` evaluator types Act 2's Nadia missions
need, the persistent crafted-recipe counter they require, and the Notes app's
new "Collective ledger" section. Full detail in `.scratch/collective-act2/spec.md`
§5.1 and §5.2 — read it before starting. This mirrors Act 1's objectives-engine
ticket (`.scratch/collective-act1_COMPLETED/issues/02-objectives-engine_COMPLETED.md`)
in shape: pure engine + rendering, testable against synthetic state, no
narrative content of its own.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Three new evaluator types exist in `systems/objectives.gd`:
      `alarm_defend_wins` (counts `Raiding.resolve_defend_outcome(won=true)`
      calls against a Collective-owned vein since activation), `faction_vein_seeded_count`
      (counts new Collective-owned veins created via `Factions.create_faction_vein()`
      or `VeinTrade.sell_to_faction()` since activation), `items_crafted_set`
      (at least one successful craft of each of `["blast","shield","pansPrank"]`
      since activation). Each tested against synthetic state, including
      `items_crafted_set` against a partial-checklist state (two of three
      crafted) to confirm it doesn't complete early.
- [ ] `refresh()` stays idempotent and never awards anything — same contract
      as the existing five evaluator types.
- [ ] `state.player.craftedCounts` (flat `recipeKey -> int` dict) added to
      `GameState`'s schema, incremented in `Crafting.attempt_craft()`'s success
      branch alongside its existing `inventory_add()` call.
- [ ] New evaluator boundaries wired into `Objectives.refresh()`'s call sites:
      `Crafting.attempt_craft()`, `Raiding.resolve_defend_outcome()`,
      `Factions.create_faction_vein()`/`VeinTrade.sell_to_faction()` (the last
      may already call refresh via an existing boundary — confirm rather than
      duplicate).
- [ ] `systems/todo.gd` gains a Collective ledger Notes section: a live-rendered
      list of every site where `factionVein.factionId == "collective"`
      (district, ore type, rough security read), unlocked when `colA2Stage`
      reaches `"hardening"`. No new state — reads `state.world.sites` directly.
      Fine to ship gated on a flag that doesn't get set until ticket 06 lands.
- [ ] Data validity: the three new objective ids/params are checked by
      `GameData.validate()` same as the existing five types.

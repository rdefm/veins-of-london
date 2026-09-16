# 11 — Bench.grant_effect() + NPC/faction collision wiring

**What to build:** The shared mechanism NPC and faction content calls to teach a player an effect directly — instantly, with no ore or time cost — and the contract for what happens when the player already knows it. This ticket is the mechanism and its collision-handling contract only; authoring the actual James/faction teaching scenes and their prose is out of scope (a separate content ticket).

**Blocked by:** 10 — Effect content pass.

**Status:** ready-for-agent

- [ ] `Bench.grant_effect(id) -> enum` in `systems/bench.gd`: the single shared entry point any NPC/faction content calls to teach an effect. Sets the effect's cell to `found` (if not already) with no ore/time cost, and returns an enum indicating which case applied.
- [ ] Enum branches per vision-doc §12.1: `GRANTED` (player didn't have it — now does, exactly like an experiment success but free); `ALREADY_KNOWN_TAUGHT_APPROACH` and `ALREADY_KNOWN_XP_FALLBACK` (or equivalent collision cases) for when the player already discovered it themselves — the return value lets calling event prose acknowledge that fact rather than silently granting nothing.
- [ ] Every effect grantable this way has a real, discoverable `discovery` cell (from ticket 10) — `grant_effect()` is never the only channel to an effect.
- [ ] `tests/test_bench.gd` extended: `Bench.grant_effect()` return-enum branches for all collision cases — granting a fresh effect, granting an already-self-discovered effect, and any other case vision-doc §12.1 defines; ore/time are never deducted by `grant_effect()` regardless of branch.
- [ ] Syntax check clean on all touched `.gd` files.

# 11 — Retire the floating-vein raid scaffolding

**What to build:** Ticket 06 (Direction B's daily-tick raid trigger) added a `state.factions[id].veins` list and a floating-vein branch in `Raiding.resolve_raid_outcome()` so a raided vein with no site could still transfer to the attacking faction, because free-floating player veins could still be created at the time. Ticket 09 closes off every path that creates a new one, so that scaffolding is now unreachable in practice and should be removed: `Raiding.roll_raid_attempts()` goes back to only considering site-tied veins (`siteId` resolving to a live `state.world.sites` entry), `Raiding.resolve_raid_outcome()` drops its siteless branch back to the single site-tied transfer, and `state.factions[id].veins` is removed from `GameState`'s faction schema (and its `SaveManager` int-restore handling). No migration for any pre-existing floating veins from before ticket 09 landed, or from old saves — explicitly out of scope per product decision.

**Blocked by:** 09 (only correct to remove the fallback once no new floating veins can be created)

**Status:** ready-for-agent

- [ ] `Raiding.roll_raid_attempts()` only considers player veins with a `siteId` resolving to a live site — ticket 06's original, pre-floating-vein-fix behaviour
- [ ] `Raiding.resolve_raid_outcome()` no longer branches on a null `siteId` — a single site-tied transfer path only
- [ ] `state.factions[id].veins` and its `SaveManager` int-restore handling are removed from `GameState`'s faction schema
- [ ] Tests updated: remove or replace ticket 06's floating-vein-specific test cases (the free-floating-vein inclusion test in `roll_raid_attempts`, the free-floating transfer test in `resolve_raid_outcome`, and the `factions.<id>.veins` schema assertion in `test_gamestate.gd`) with the reverted site-tied-only behaviour
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes

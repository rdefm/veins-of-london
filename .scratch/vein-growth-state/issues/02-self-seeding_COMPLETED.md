# 02 — Self-seeding at the right wall

**What to build:** a vein that sits at the growth ceiling for long enough spawns a new player vein on an unclaimed site in the same district — the reward for holding a wild posture rather than cashing out.

**Blocked by:** 01 (core growth model — needs `growth`/`ceiling`/drift and the daily-tick step in place).

**Status:** ready-for-agent

- [ ] `rampantDays` increments by 1 each daily tick a vein sits at its ceiling; resets to 0 the moment `growth` drops below ceiling by any means (drift, prune, collapse never applies here since it's the opposite wall).
- [ ] `Cultivating.self_seed(vein)` implemented: at `rampantDays == RAMPANT_SEED_DAYS` (5), pick an unclaimed site uniformly at random in the same district. If one exists: claim it for the player, create a new player vein at `growth = 60` (`selfSeedGrowth`), ore type and hospitability from the site, its own generated location; reset the parent's `rampantDays = 0`; notification (PROSE-REVIEW — draft against `docs/CONTENT-GUIDE.md`, flag for sign-off). If none exists: no-op, `rampantDays` holds at 5 and retries next tick (counter is not lost or reset by a failed attempt).
- [ ] Runs in `daily_tick` step ④, after drift and the collapse roll (spec §10: drift → collapse roll → self-seed, same step, that order).
- [ ] Self-seeding claims an existing site only — no `siteCap` plumbing needed, but it does consume unclaimed sites in the district (competes with player prospecting — confirmed intentional, not a bug to guard against).
- [ ] Faction veins never self-seed — confirm the drift/tick pass only calls `self_seed` for player veins.
- [ ] `test_cultivating.gd` / `test_time_system.gd` coverage per spec §11 item 7: fires at exactly 5 rampant days, claims an unclaimed site in-district, does not breach `siteCap`, no-ops without losing its counter when no unclaimed site exists.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.

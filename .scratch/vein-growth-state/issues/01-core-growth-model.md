# 01 — Core growth model

**What to build:** replace a vein's `devBar`/`level`/`charged`/`chargeBlocks` with a single `growth: int` axis (0..ceiling, neutral 50) that drifts daily toward whichever wall it was last left leaning, and the three actions — Cultivate, Prune (light), Prune (hard) — that push it around. This is the foundation every other ticket in this feature depends on; it must be complete and independently correct before anything else touches it.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `data/vein_growth.json` added per spec §4 (bands, yield/cultivate/collapse/seed constants, `terroirYieldMult`); `GameData` loads and validates it (bands contiguous, cover 0..100, exactly one `drift: 0` band per side of neutral plus `collapsed`).
- [ ] `data/vein_levels.json` and its `GameData` loader/validation/constant deleted.
- [ ] New vein dict shape per spec §2.1 (`growth`, `rampantDays`, no `devBar`/`charged`/`chargeBlocks`/`level`/`levelLabel`); `Cultivating.make_vein()` rewritten. Faction veins carry the same fields plus `factionId`.
- [ ] `Cultivating.growth_band(vein)`, `band_drift(growth)`, `drift_veins()` implemented; `drift_veins()` replaces `recharge_veins()` at `daily_tick` step ④, same position, one pass over player veins and faction veins.
- [ ] Drift formula per spec §2.3: `delta = band_drift(growth)`, direction by side of neutral, clamp to `[0, ceiling(vein)]`.
- [ ] `Cultivating.cultivate()` rewritten: same success roll (`cultChance`), `cultivate_gain()` per spec §2.4 formula, XP awards unchanged (20/8).
- [ ] `Cultivating.prune(vein_id, depth)` implemented for light (-15) and hard (-40), clamped at 0; `prune_yield()` per spec §2.4 (`points above neutral removed × YIELD_PER_POINT × terroir_yield_mult × hard_bonus`, then `apply_yield_bonus`); yields 0 at or below neutral. Cultivating XP awarded on the existing harvest schedule.
- [ ] `harvest_cautious`, `harvest_full` deleted; both call sites elsewhere in the codebase updated to prune light/hard as the spec's mapping dictates.
- [ ] Left wall (spec §2.5): `growth` pins at 0 (never negative), vein enters `collapsed` band, still cultivable at max gain. `Cultivating.collapse_vein()` runs the `COLLAPSE_CHANCE_PER_DAY = 0.15` roll each tick a vein sits at 0; on landing, remove the vein — **branch by owner**: a player vein's site reverts to unclaimed (`site.claimed = false`); a faction vein's site is deleted outright, matching NPC-abandonment semantics (confirmed in review — same 15%/day roll for both, but the faction outcome is deletion, not reversion). Reuses the existing collapse notification line for the player case.
- [ ] Right wall clamp only in this ticket (growth pins at `ceiling(vein)`, no drift, no decay); self-seeding itself is ticket 02.
- [ ] `Cultivating.value_tier(vein)` added (`1 + floor(growth / 20)`, 1..6). Not yet consumed elsewhere — that's ticket 03 — but present and tested here.
- [ ] `Cultivating.ceiling(vein)` (100, or 120 with `wildCeiling` bonus — bonus itself lands in ticket 05, but `ceiling()` must accept a vein that already carries it) and `Cultivating.days_to_wall(vein)` added.
- [ ] Deleted: `level_up_vein`, `_level_down_vein`, `dev_fraction`, `get_level_cap`, `is_at_max_level`, `get_effective_recharge_blocks`, `LEVEL_CAP`. Kept unchanged: `generate_location_name`, `get_cult_chance`, `apply_yield_bonus`, `award_xp`, `find_vein`, `make_vein_id`, security/alarm sections.
- [ ] `Sites.attempt_seed()`, the `hasNaturalVein` grant, and the tutorial's granted vein all start new veins at `growth = 20` (`seedGrowth`).
- [ ] `SaveManager.SAVE_VERSION` bumped 1 → 2; loader rejects a v1 save with a clear message (no migrator). Per-vein sanitising lists become `["growth", "rampantDays", "claimedOnDay"]`.
- [ ] `test_cultivating.gd`, `test_sites.gd`, `test_time_system.gd`, `test_savemanager.gd`, `test_gamedata.gd` rewritten/passing. New coverage per spec §11 items 1–6: symmetric/sided drift; the 26-day pacing figure (56→ceiling and 44→0 both land 24–28 ticks); prune yields nothing at/below neutral, hard prune yields only above-neutral points; bottoming-out survivable and recoverable; collapse roll fires at 0.15/day and not before, site reverts (player) vs deletes (faction) correctly; fresh-seed-at-20 on every creation path, climbable to neutral in ~12 skill-1 blocks.
- [ ] `docs/REFERENCE.md` updated: §1.2 (levels table → growth table), §2.1 (vein dict), §3.1④ (daily tick), §3.4 (cultivating & harvest → cultivating & pruning), §7 (debug-start description).
- [ ] `docs/M1-LONDON.md` exit criterion 2 corrected (stale "travel costs blocks" line, already false since the travel-surcharge removal).
- [ ] `CONTEXT.md` Language section: add Growth, Band, Prune, Rampant, Terroir; update the Vein entry (currently references levels); retire "charge", "dev bar", "vein level".
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean on every touched file; `scripts/run_tests.sh` green.

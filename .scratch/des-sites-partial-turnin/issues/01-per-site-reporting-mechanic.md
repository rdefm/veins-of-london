# 01 — Per-site reporting mechanic for Des' find-ground quest

**What to build:** The `col_a1_des_sites` objective ("Find ground for the Collective" — one unclaimed fair+ fate site, one unclaimed fair+ physics site) currently only completes when both qualifying sites are unclaimed simultaneously at one evaluation pass (`Objectives._eval_sites_discovered_matching`), then both convert to Collective veins at once via `_faction_seed_reported_sites`. There is no partial credit: if one qualifying site is later claimed or re-rolled away before the second is found, that progress is lost.

Build the underlying mechanic (no UI yet — that's ticket 02) to let each ore type be reported independently, the moment a qualifying site for it exists:

- A system function (e.g. `Collective.report_des_site(ore_type)`) that: finds a currently-qualifying, not-yet-reported site for that ore type (reuse `Objectives.site_matches_discovery_params()`), converts it immediately to a Collective-owned vein (reuse `Sites.seed_faction_vein()`, the same op `_faction_seed_reported_sites` already calls), awards +4 Collective relation, and records the report into the objective's progress state (e.g. `progress["reportedSiteIds"][ore_type] = site_id`) — cumulative across calls, not overwritten.
- The objective completes once every required ore type (`fate`, `physics`) has been reported, in either order, regardless of whether both were ever unclaimed at the same time.
- `_eval_sites_discovered_matching`/`_faction_seed_reported_sites`'s "convert both at once" path is superseded by this per-site path for `col_a1_des_sites` specifically — decide whether to repurpose or replace the existing evaluator for this objective type without breaking other uses of `sites_discovered_matching` if any exist (check `data/objectives.json` for other consumers of this type before assuming it's Des-only).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A system function reports one qualifying site for a given ore type: converts it to a Collective vein immediately, awards +4 relation, and records it in the objective's progress.
- [ ] Reporting is idempotent/safe to call only when a qualifying unreported site actually exists for that ore type (no-op or explicit failure otherwise — decide and document which).
- [ ] The objective completes only once both `fate` and `physics` have been individually reported, in either order, verified by a test that reports them out of simultaneous-availability (e.g. report fate, let that site's physics counterpart appear later, report physics — objective completes without ever having both unclaimed at once).
- [ ] A site already reported for one ore type cannot be double-reported or re-matched for the other.
- [ ] Existing tests for `col_a1_des_sites`/`col_a1_des_report` (see `tests/test_col_a1_*.gd`, `tests/test_objectives.gd`) still pass or are updated to match the new per-site model.

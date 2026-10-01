# 02 — Vein seeding costs 100 ore

**What to build:** Seeding a vein costs 100 ore of the vein's own type (was 40). UI cost labels and the insufficient-ore check follow the new value.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/vein_growth.json` (`seedOreCost`), `autoload/GameData.gd` (`SEED_ORE_COST`), `systems/sites.gd` (seed attempt ~L391), `seed_result_modal.gd`, `docs/REFERENCE.md` seeding section, `tests/test_sites.gd`.

**Status:** ready-for-agent

- [ ] Seed requires and spends 100 of the vein's type; blocked below 100
- [ ] REFERENCE.md updated; tests updated/passing
- [ ] Any UI string showing the cost reads 100 (grep for hardcoded 40)

# 02 — Recipe ingredients schema migration

**What to build:** Migrate every recipe's single-ingredient field to a multi-ingredient dict, with per-ingredient cost calculation, while leaving all existing crafting behaviour byte-for-byte identical. This is the prefactor that lets a later ticket attach `discovery`/`refineStep` fields per recipe without fighting the old single-ingredient assumption baked into crafting, devices, rooms, and the HQ screen.

**Blocked by:** 01 — Approaches data + unlock resolution + Lab room rename.

**Status:** ready-for-agent

- [ ] `data/recipes.json`: every recipe's `ingredient: "time"` (singular string) migrated to `ingredients: {"time": 5}` (dict). Existing single-ingredient recipes reproduce identically as a one-key dict.
- [ ] `data/recipes.json`: `baseCalcCost` (single scalar) superseded by per-ingredient cost expressed inside each `ingredients` entry.
- [ ] `systems/crafting.gd`: `calc_cost()` re-expressed to compute cost per ingredient key, preserving the existing `max(1, round(base − (skill−1) × 0.8))` shape per ingredient. All other crafting logic (ore deduction, attempt resolution) updated to iterate `ingredients` instead of reading a single `ingredient` key.
- [ ] `systems/devices.gd`, `systems/rooms.gd` (lab room's auto-craft), `scenes/screens/hq.gd`: every read of the old `ingredient`/`baseCalcCost` fields updated to the new `ingredients` shape.
- [ ] `REFERENCE.md` §1.3 updated to document the new schema.
- [ ] `tests/test_crafting.gd` extended: existing recipes cost and craft identically pre/post migration (same ore spent, same success odds); `calc_cost()` produces correct per-ingredient costs for a multi-ingredient recipe.
- [ ] Syntax check clean on all touched `.gd` files.

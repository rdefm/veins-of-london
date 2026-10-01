# 01 — Veins much rarer outside their district's type

**What to build:** New veins should match their district's type ~75% of the time (25% off-type on average). Single-bias districts go from 0.6 → 0.75 for their type; the dual time/physics district goes 0.3/0.3 → 0.375/0.375; unbiased districts stay uniform. Off-type remainder stays split evenly across the other types (existing `compute_ore_probs` behaviour). New veins only — existing saves untouched (type is rolled at vein creation, so a data change suffices; no migration).

**Blocked by:** None — can start immediately.

**Relevant files:** `data/districts.json` (`oreBias`), `systems/sites.gd` (`compute_ore_probs`, `roll_ore_type`), `docs/REFERENCE.md` district table / oreBias rule, `tests/test_sites.gd`.

**Status:** ready-for-agent

- [ ] oreBias values updated as above; REFERENCE.md matches
- [ ] Test: single-bias district probs = 0.75 main, 0.0625 each other; dual district 0.375/0.375/0.0833…
- [ ] No save migration; existing veins keep their type

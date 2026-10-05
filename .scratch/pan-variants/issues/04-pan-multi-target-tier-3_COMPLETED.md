# 04 — Pan multi-target at tier 3

**What to build:** Pan items unlock multi-target at tier 3. The craft checkbox (`item-tiers` 07) covers the four Pan variants; the multi-target version applies the effect to all enemies.

**Blocked by:** `item-tiers` 07 — Multi-target craft checkbox; 02 — Panic and Rapture; 03 — Panger and Pandemonium.

**Relevant files:** `systems/combat.gd`, `systems/crafting.gd`, `data/recipes.json`, crafting screen, combat tests.

**Status:** ready-for-agent

- [ ] Checkbox offered for Pan items at tier ≥ 3 (single by default)
- [ ] Multi version applies each status to every enemy, each with independent random rolls
- [ ] Tests pass

# 01 — New item roster (data + placeholder icons)

**What to build:** All 24 new items from `docs/brainstorm.md` §3, §4 and §4.1 exist as real item ids: nearMiss, sodsLaw, happyAccident, introduction, smellingSalts, rootFeed, bloom, borrowedTime, patina, ricochet, deadweight, signalFailure, trueLevel, dejaVu, skeletonKey, goodYear, secondImpression, stiffUpperLip, heavyMetal, coldFeet, nostalgia, navvysDraught, cleanSlate, keystone. Each gets a recipe row (name, symbol, ingredients, baseSuccess, effectPower, xp per the brainstorm tables), a consumable price (`xpReward × 6` rule, lore goods as documented exceptions like Rejuvenation), a description (PROSE-REVIEW, from brainstorm's quoted lines) and a shared placeholder icon. Items show in the Bag/inventory and can be granted via debug. No mechanics yet. Brainstorm doesn't give baseSucc/effectPower/xp for cleanSlate or keystone, so ask before you pick numbers for those two. All numbers are placeholders until playtest.

**Blocked by:** None — can start immediately.

**Relevant files:** `docs/brainstorm.md`, `data/recipes.json` (recipes + `CONSUMABLE_PRICES`), `data/constants.json` (item lists), `assets/combat/icons/`, `systems/consumables.gd`, `systems/bag.gd`, `CODEMAP.md`; REFERENCE §1.3 `data/recipes.json`.

**Status:** ready-for-agent

- [ ] All 24 ids load at boot with recipe row, price, description, placeholder icon
- [ ] Boot/data validation passes, existing tests pass
- [ ] Every placeholder number is tagged for balance; new prose flagged PROSE-REVIEW
- [ ] Ask the human for the cleanSlate/keystone numbers before you set them
- [ ] REFERENCE §1.3 and CODEMAP updated

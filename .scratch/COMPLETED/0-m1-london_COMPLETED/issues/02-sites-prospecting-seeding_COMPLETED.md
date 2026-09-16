# 02 — Sites, prospecting & seeding revamp

**What to build:** `state.world.sites`; the prospect action (D2: tier roll with modifiers/floors/normalisation, oreType per district bias, discovery bonuses, `siteCap` re-roll restricted to truly-unclaimed sites only per `CONTEXT.md`'s three site-claim states); `attemptSeed(siteId)` replacing free-floating seeding; hospitability bonus application to the existing cultivating/harvest systems (`recharge`, `maxLevel`, `yield` — yield per the post-roll-scaling formula in D2, `finalYield = max(rolledYield + 1, round(rolledYield * 1.15))`).

System-only, verified headlessly — no UI. The Map tab ticket (04) wires these into buttons.

**Blocked by:** 01 (needs `currentDistrict` and district data to compute `siteQualityMod`/`oreBias` and the "current district == site district" check).

**Status:** ready-for-agent

- [ ] Site dict matches D2's schema exactly, including `npcClaimedDay:null`
- [ ] Tier roll matches the weight table + modifiers + floors (barren floor 5, poor floor 0) + normalisation
- [ ] `siteCap` re-roll never touches player-claimed or NPC-claimed sites — only true-unclaimed, worst-tier-first, oldest breaks ties
- [ ] Discovery bonuses: rich → one of recharge/maxLevel/yield uniformly; saturated → all three + 5% `hasNaturalVein`; natural-vein bonus vein gets its own freshly-generated `location`
- [ ] `attemptSeed()` requires current district == site district, site truly unclaimed (NOT npcClaimed), tier != barren, 40 ore of the site's oreType; success/fail per D2's tierMod table
- [ ] Hospitability bonuses read correctly by cultivating/harvest: recharge (−1 min 1, stacks with King's Cross), maxLevel (cap 6), yield (post-roll formula above)
- [ ] Tests: weight-table math incl. floors/caps, bonus rolls, natural-vein-at-5%, yield-formula (assert the +1-minimum floor actually bites at low vein levels)
- [ ] `godot --headless --check-only --script` clean on all touched files

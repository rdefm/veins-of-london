# 87 — Map: recycle slot indices so veins stop going missing / unclaimed sites stop overlapping

**What to build:** A district's slot buffer for map layout is sized for one specific case (a saturated site's bonus natural vein) and slot indices are only ever handed out, never reclaimed when a site/vein is removed. Once a district's total churn (sites and veins created and later removed — sold, collapsed, faction vein death, etc.) exceeds the fixed buffer over a long session, overflow items get clamped onto the same last slot and render stacked invisibly on top of each other — matching both reported symptoms: a district's list view shows more veins than the map visibly renders, and unclaimed sites appear to overlap. This is a root-cause fix (recycle freed slots) rather than a band-aid (a bigger buffer only delays the same failure) — and is expected to matter more soon, since a recent ticket deliberately increased faction vein churn rates.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A district's slot index is returned to that district's available pool whenever the site/vein occupying it is removed, so the counter never exhausts regardless of session length.
- [ ] Every removal path that ends a site's or vein's existence in a district is enumerated and instrumented to free its slot (vein sold to a faction changing the site's slot ownership, vein collapse, faction vein death via prune-back/collapse, and any other removal path found).
- [ ] No two live stops in a district ever end up clamped onto the same slot, however much churn the district has seen.
- [ ] Test seeds enough churn in one district to exceed the old fixed buffer and confirms no slot collisions occur.
- [ ] Coordinated with the amendment to ticket 74 (item 8 of the source spec) since both change how/when a stop's slot position can move — flag if the two pieces of work conflict.

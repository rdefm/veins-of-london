# 06 — Studio home tier

**What to build:** A new home tier, Studio (one-room flat), sits between Bedsit and Flat. Buy £100,000, rent £60/day, owned daily cost £35, raid base chance 0.07. Reuses Bedsit's floorplan and HQ visuals until new art lands. Harrow's shows it as the next tier up from Bedsit (rent or buy) and the move-down from Flat. Existing tier references (tier numbers, `minTier` gates, saves) keep working. Other tiers' prices unchanged.

**Open decision (STOP and ask before implementing):** owned daily cost is currently a formula (ADR 0006: `utilitiesBase + utilitiesFraction × dailyCost` = 50 + 0.1×60 = £56). £35 needs either a per-tier owned-cost override or a formula change.

**Blocked by:** None — can start once the decision above is made.

**Relevant files:** `data/home.json`, `data/floorplans.json`, `data/hq_visuals.json`, `systems/home.gd`, `systems/time_system.gd`, `scenes/phone_apps/property_app.gd`, `scenes/components/floorplan_view.gd`, `autoload/SaveManager.gd`, `docs/adr/` (ADR 0006); REFERENCE §1.7, §3.3.

**Status:** needs-info

- [ ] Studio tier in data with the numbers above
- [ ] Owned bill = £35/day
- [ ] Harrow's shows Studio correctly from Bedsit and from Flat
- [ ] Studio uses Bedsit floorplan + HQ visuals
- [ ] Old saves load; tier moves (rent/buy/buy-out/downgrade/forced downgrade) work through Studio
- [ ] REFERENCE updated

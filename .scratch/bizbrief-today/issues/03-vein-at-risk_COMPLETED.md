# 03 — Vein-at-risk row with nights-to-collapse estimate

**What to build:** Player veins in a low growth band and leaning down get an estimated nights-to-collapse from the level-driven drift rule (expected value, no RNG), phrased "~N nights". At or under the data threshold the row is Urgent; above it the vein goes to Routine. The action ("Cultivate") takes the player straight to that vein on the Map. The row disappears once the vein is no longer at risk.

**Blocked by:** 01 — Tracer: DailyBrief projection + Today card.

**Relevant files:** `systems/cultivating.gd` (`growth_band`, `drift_magnitude`, `_band_for_growth`, `drift_veins`), `systems/vein_list_nav.gd`, `systems/map_style.gd` (`is_risk_band`), `data/vein_growth.json`, `systems/daily_brief.gd`, `data/daily_brief.json`, BizBrief action mapping in `scenes/phone_apps/bizbrief_app.gd`, `tests/test_daily_brief.gd`. REFERENCE.md §1.2 "`data/vein_growth.json`", §2.1 "Vein dict", §3.4 "Cultivating & pruning".

**Status:** ready-for-agent

- [ ] Estimate matches the drift rule for a given level + growth (test)
- [ ] ≤ threshold → Urgent; > threshold → Routine; threshold in data
- [ ] Consequence uses "~N nights"; never promises exact timing
- [ ] `map_vein` + `veinId` descriptor routes to that vein on the Map
- [ ] Row drops off after cultivation lifts it out of risk

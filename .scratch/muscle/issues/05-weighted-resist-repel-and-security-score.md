# 05 — Weighted resist/repel and Security score

**What to build:** Guard level and traits change how safe a place is. Vein resist = lock/ward tier resist (0/15/35) + Σ over posted guards of 20 × level weight. Repel = min(Σ 0.15 × repel weight, 0.75), then kit adds its existing bonus up to the 0.90 kit cap. HQ raid chance: each posted HQ guard's `raidReduction` (0.05) scales by weight (spec Further Notes (a) — implement as the spec assumes, 0.05 × weight). Officer bonus terms are zero-valued hooks for the officer spec's own tickets.

A single **Security score** (0–100) per vein and HQ: round(40 × hardware ÷ place max hardware + 60 × min(1, repel ÷ 0.75)). Vein hardware = lock/ward resist (max 35); HQ hardware = installed `raidReduction` excluding guards (max 0.18). Bands: 0–24 Exposed / 25–49 Light / 50–74 Solid / 75+ Fortified. Shown on the vein detail panel and the Posts tab headers. Readout only.

**Blocked by:** 03 — Posting and player guard-count cutover.

**Relevant files:**
- `systems/muscle.gd` (`weight`, `repel_weight`, `post_weight_sum`, `post_repel_weight_sum`, `security_score`)
- `systems/cultivating.gd` (`vein_raid_resist`), `systems/raiding.gd` (`guard_repel_chance`, `guards_repel`, `_guards_repel_defend_raid`), `systems/home.gd` (`get_home_raid_chance`, `guard_repel_chance`), `systems/guard_kit.gd` (`repel_chance_with`)
- `scenes/components/vein_detail_panel.gd`, Security screen Posts tab
- Tests: `tests/test_raiding.gd`, `tests/test_home.gd`, `tests/test_muscle.gd`, `tests/test_cultivating.gd`
- REFERENCE.md §1.6, §3.12

**Status:** ready-for-agent

- [ ] All-L1, no-trait roster gives today's resist, repel and HQ raid chance exactly
- [ ] Higher levels raise resist and repel per the formulas; Watchful/Mouthy/Flaky change repel only
- [ ] Repel capped at 0.75 before kit, 0.90 with kit
- [ ] Score examples: warded vein alone = 40; warded + 1 L1 = 52; bands map correctly at 24/25, 49/50, 74/75
- [ ] Score + band visible on vein panel and Posts headers
- [ ] On-device check listed: score + band on vein panel and Posts headers

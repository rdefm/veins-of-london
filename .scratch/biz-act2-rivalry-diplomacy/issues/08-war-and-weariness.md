# 08 — War + weariness

**What to build:** Two sides are **at war** when their stance is Hostile and they've traded a hostile act (raid, flood, stockpile raid, shortfall steal) within N days. War ends after that many quiet days, or on a truce (ticket 09). Each side at war builds **weariness** (0–100). In descending weight it comes from losses, cash drain above peacetime, extra fronts and days at war. It decays when not at war. Factions have `acceptPeace`/`offerPeace` thresholds in data. The player has a weariness meter with `nag` and `extreme` thresholds, and Archie/James message escalating nags. BizBrief shows the weariness meter and war status. "War declared" is a Ticker headline for faction pairs.

**Blocked by:** 04 — Escalation framework + raid rung.

**Relevant files:** `systems/faction_ai.gd`, `systems/raiding.gd` / `systems/factions.gd` (hostile-act hooks, losses), `systems/guard_upkeep.gd` / `systems/guard_kit.gd` (cash drain), `systems/barometer.gd`, `data/factions.json` (thresholds), `data/constants.json`, `SaveManager`, `scenes/phone_apps/bizbrief_app.gd`, `tests/test_faction_ai.gd`, `tests/test_savemanager.gd`, `CONTEXT.md` (war, weariness), `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 42–48, §War, weariness, truce. REFERENCE.md §1.8, §3.1.

**Status:** ready-for-agent

- [ ] Rollover test: Hostile + a raid starts a war record. Quiet days past the window end it.
- [ ] Rollover test: losses raise weariness more than days at war alone. A second war multiplies it. Weariness decays out of war.
- [ ] The player's weariness crossing `nag` sends Archie/James messages, escalating by nag level.
- [ ] BizBrief shows the player's weariness meter and current wars.
- [ ] A faction-pair war declaration makes a Ticker headline.
- [ ] Wars and player weariness are saved and backfilled. Weights in JSON. CONTEXT, REFERENCE and CODEMAP updated. `PROSE-REVIEW:` for nags and headlines.

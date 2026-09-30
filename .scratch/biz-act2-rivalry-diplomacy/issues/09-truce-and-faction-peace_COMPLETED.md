# 09 — Truce + faction–faction peace

**What to build:** A **truce** record stops all moves between two parties for its duration. It sets their relation to just above the Hostile band and adds a daily relation bonus on top of drift. Breaking a truce (moving against the other side during it) costs the breaker a large relation loss with every faction. Factions at war make peace with each other using the negotiation scorer with auto-picked terms. Payments and veins are valued at market value, truce days are weighted by weariness, and the acceptance bar falls as weariness rises. A truce signed between factions is a Ticker headline.

**Blocked by:** 08 — War + weariness.

**Relevant files:** `systems/faction_ai.gd` (scorer, truce list), `systems/vein_trade.gd` / `systems/raiding.gd` (`transfer_*` paths for vein swaps), `systems/barometer.gd`, `data/constants.json` (truce defaults, scorer constants), `SaveManager`, `tests/test_faction_ai.gd`, `CONTEXT.md` (truce), `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 56–58, 61–62, §War, weariness, truce. REFERENCE.md §3.1.

**Status:** ready-for-agent

- [ ] Rollover test: two factions both past `acceptPeace`, with one at `offerPeace`, sign a truce. The war ends and a headline fires.
- [ ] Rollover test: a truce blocks moves between its parties, and relation gets the daily bonus.
- [ ] Test: a move against a truce partner drops the breaker's relation with every faction.
- [ ] The truce-hook stub from ticket 04 is now real. Truces are saved and backfilled. Constants in JSON. CONTEXT, REFERENCE and CODEMAP updated.

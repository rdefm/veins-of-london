# 05 — Producer market moves

**What to build:** The Collective and Firm can fight with production. **Flood:** sell the target's ore below value, at a real cost to the flooder. It goes through Market supply recording, so price responds, and carries a named price-chart annotation plus a Ticker headline when the target is a faction. **Withhold:** stop selling to squeeze the target. **Outbid for sites:** a rival claims a site the player is prospecting or eyeing before the player can.

**Blocked by:** 04 — Escalation framework + raid rung.

**Relevant files:** `systems/faction_sim.gd` (new flood/withhold actions, `_sell`, `reserve`), `systems/market.gd` (`record_supply`, `_annotate`), `systems/sites.gd` / `systems/factions.gd` (`pick_claimant`, NPC claim path), `systems/faction_ai.gd`, `systems/barometer.gd`, `tests/test_faction_ai.gd`, `tests/test_market.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 21, 29, 31, 38, 40. REFERENCE.md §3.13, §1.9.

**Status:** ready-for-agent

- [ ] Rollover test: a Firm flood records supply, adds a Firm-named annotation on the ore's chart, lowers price the next reprice, and costs the Firm cash (sold below value).
- [ ] Rollover test: withhold stops the faction selling that good for the duration.
- [ ] Rollover test: outbid claims a site the player has discovered but not claimed, and messages the player.
- [ ] Moves only fire when affordable and when the band allows.
- [ ] Faction-vs-faction flood makes a Ticker headline. Outbid is player-only.
- [ ] Costs are in JSON. REFERENCE and CODEMAP updated. Prose flagged `PROSE-REVIEW:`.

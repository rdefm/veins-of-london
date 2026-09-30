# 07 — Conclave targeted moves

**What to build:** The Conclave fights a target through the market. **Undercut:** it sells the goods the target sells, below the target's price. **Deny:** it buys up the goods the target needs. Both go through Market recording with named annotations. The Conclave has no raid rung.

**Blocked by:** 04 — Escalation framework + raid rung.

**Relevant files:** `systems/faction_sim.gd` (targeted buy/deny, `_buy`), `systems/market.gd`, `systems/faction_ai.gd`, `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` story 24, §Escalation menus, §Market. REFERENCE.md §3.13.

**Status:** ready-for-agent

- [ ] Rollover test: an undercut records Conclave supply of the target's sold good with a Conclave annotation, and the price moves on reprice.
- [ ] Rollover test: deny records Conclave demand and holdings rise, so the target's needed good gets pricier/scarcer.
- [ ] The Conclave never queues a raid.
- [ ] Constants in JSON. REFERENCE and CODEMAP updated.

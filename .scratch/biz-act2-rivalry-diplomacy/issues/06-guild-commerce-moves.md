# 06 — Guild commerce moves

**What to build:** The Guild fights with commerce. **Poach:** a rival's cheaper counter-offer attaches to one of the player's pending contract renewals, and the buyer goes with the rival unless the player matches. **Withhold items:** the Guild stops selling items the player needs. **Lowball buyout:** when the player is short of cash or has just lost a vein, the Guild (or any faction at the market rung) messages a buyout offer below the vein's current quote. Accepting goes through the existing sell-to-faction path.

**Blocked by:** 04 — Escalation framework + raid rung.

**Relevant files:** `systems/offers.gd`, `systems/contracts.gd` (renewals), `systems/vein_trade.gd` (quote, sell-to-faction), `systems/faction_sim.gd`, `systems/messages.gd` + pending-message mechanism (see `systems/collective.gd`), `systems/faction_ai.gd`, the contract renewal UI in `scenes/phone_apps/bizbrief_app.gd`, `tests/test_offers.gd`, `tests/test_contracts.gd`, `tests/test_vein_trade.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 22, 30, 32, §Contracts / Offers, §VeinTrade. REFERENCE.md §3.6a.

**Status:** ready-for-agent

- [ ] Test: a poached renewal the player matches stays with the player at the matched price. An unmatched one lapses to the rival.
- [ ] The renewal UI shows the rival's counter-offer and a match action.
- [ ] Rollover test: withhold removes the item from the Guild's for-sale stock for the duration.
- [ ] Test: a lowball offer is priced below the vein quote and arrives as an actionable message. Accepting transfers the vein through the existing path and pays cash.
- [ ] Poach is skipped between factions. REFERENCE, CODEMAP and `PROSE-REVIEW:` done.

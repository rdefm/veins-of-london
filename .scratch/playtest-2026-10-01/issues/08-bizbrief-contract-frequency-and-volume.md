# 08 — BizBrief contracts: retune offer frequency and quantity

**What to build:** After the economy rebalance, random contract offers arrive too rarely and ask for too little. Target ~1 offer every 2 days at Sales Lv1 (scaling up with Sales level), and raise per-offer quantities to suit the rebalanced economy. First establish why the observed rate is lower than the configured curve (base 0.33 + 0.07/lvl per day) suggests — gating conditions, expiry, or roll timing — then retune data.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/offers.json` (`randomChance`, templates, expiry), `systems/offers.gd`, `systems/contracts.gd`, `systems/time_system.gd` (rollover), `docs/REFERENCE.md` Sales offers section. Ask human for target quantities if REFERENCE gives no basis.

**Status:** ready-for-agent

- [ ] Cause of low observed frequency documented
- [ ] Simulated N-day test: mean offer interval ~2 days at Sales Lv1
- [ ] Quantities raised; REFERENCE.md updated with new numbers

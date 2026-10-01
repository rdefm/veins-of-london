# 11b — Conclave stabiliser stockpile

**What to build:** The Conclave keeps a stockpile of each good, held back for steadying the market. Its bargain-hunting and everyday surplus sales never touch it. When a spike runs long enough for the stabiliser to act, the Conclave sells into it from this stockpile. The stockpile fills two ways. Crash buys go into it. A slow daily top-up also buys a good while its price is at or below base, up to a daily cap, spending only cash above a floor. Topping up should never cause the spikes it is meant to damp. Over time the Conclave profits from buying low and selling high, but each intervention still costs it against the day's price. The stockpile is the base for the later Conclave positions work.

**Blocked by:** 11 — Conclave stabiliser (done). Can start immediately.

**Relevant files:** `systems/faction_sim.gd` (`reserve`, `_sell_surplus`, `_arbitrage`, `for_sale`, `stabilise_sell`, `stabilise_buy`), `systems/faction_ai.gd` (`stabilise`, Conclave stabiliser section), `systems/time_system.gd` (⑥.5g3), `data/constants.json` (`factionConclave.stabiliser`), `autoload/SaveManager.gd` (if new state), `tests/test_faction_ai.gd`, `tests/test_faction_sim.gd`, `CODEMAP.md`. REFERENCE.md §3.1 "Conclave stabiliser", §1.11 "Faction Conclave", §3.13 "Annotations".

**Status:** ready-for-agent

- [ ] The stockpile target for each good is set in JSON, along with the top-up's daily cap, price ceiling and cash floor.
- [ ] Rollover test: Conclave bargain-hunting and surplus selling leave stockpile units unsold, even when the price is above the bargain-hunting sell line.
- [ ] Rollover test: the top-up buys toward the target only while the price is at or below base. It stays within the daily cap and never spends cash below the floor.
- [ ] Rollover test: a spike held for the stabiliser's run is sold from the stockpile. A crash buy adds to it.
- [ ] Existing faction_sim and faction_ai tests still pass. REFERENCE §3.1/§1.11 and CODEMAP updated.

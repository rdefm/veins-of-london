# 01 — Market core + Archie ore lane

**What to build:** London gets a living market for every good (five ore types + every recipe key). Each day the rollover reprices every good from a hidden London stock: today's recorded supply/demand plus stand-in London supply/demand move the stock, rest-of-London reversion pulls it toward `normalStock`, target price = base × curve(stock/normalStock) clamped to [0.2×, 4×] base, and the price moves a smoothed fraction toward target (integer £). History is kept (bounded, ~28 days). Tracer lane: selling ore to Archie executes at today's London quote (then district mod and Archie cut as today) and records supply — mugged or not — so the following days' price reacts. A single sim-start switch (`day1` default / `bizA2`) gates the sim: before start, quote returns base and reprice is a no-op. Old saves get a `market` backfilled at resting prices. Spec: `.scratch/biz-act2-market-sim/spec.md` §Market, §Stand-in London, §State, §Data.

Feel targets (pin numbers in JSON + REFERENCE.md): idle equilibrium ~1.1–1.2× base; normal player pace ≈ base; a week-of-output dump resettles in 2–4 days; London volume sized so an end-of-Act-1 player is ~10–15% of their main ore type.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/market.gd` (new) — quote, 2-day average quote, `record_supply` / `record_demand(kind, type, qty, source)`, daily reprice, stand-in London provider (single read point per good)
- `systems/economy.gd` (Archie lane ore branch, ~line 95)
- `systems/time_system.gd` (`daily_tick` — new reprice step after the ⑥.3–⑥.5c contracts/business/offers steps and after ① Barometer)
- `autoload/SaveManager.gd` (backfill), `autoload/GameState.gd` (initial state)
- `data/market.json` (new) or `data/constants.json`; `data/ore_types.json` (`basePrice`); consumable price table (item base)
- `tests/test_market.gd` (new), `tests/test_economy.gd`, `tests/test_time_system.gd`, `tests/test_savemanager.gd`
- `docs/REFERENCE.md` — new Market section (formulas); §3.1 Time, rest, daily tick (new step)
- `CODEMAP.md` (market.gd + data row)

**Status:** ready-for-agent

- [ ] `market` state is pure data: per good `{stock, price, prevPrice, history[]}`, today's `supply`/`demand` tallies with source breakdown, `startedDay`; all constants and per-good `normalStock` / stand-in supply / stand-in demand in JSON
- [ ] Pure quote tests: clamp at 0.2× and 4×, zero stock, stock exactly normal, 2-day average with and without history
- [ ] Rollover: no player sales → price drifts to idle premium and holds
- [ ] Rollover: Archie ore sale executes at today's quote; next day's price lower; back near equilibrium within 2–4 days
- [ ] Rollover: repeated dumps approach but never pass the floor; forced shortage never passes the ceiling
- [ ] Mugged Archie ore sale still records supply
- [ ] Sim-start `bizA2` → quote returns base, reprice is a no-op
- [ ] Save round-trip keeps `market`; old save backfills at resting prices
- [ ] REFERENCE.md Market section + §3.1 step; CODEMAP updated

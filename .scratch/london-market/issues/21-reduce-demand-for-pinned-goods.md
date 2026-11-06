# 21 — Reduce demand for goods pinned at max price

**What to build:** Fewer goods sit at their price ceiling at rest. The audit (spec story 89) found 10–19 goods pinned at max price for 5+ days of a 30-day sim in every seed. Many have no faction crafter or are ore-starved (Keystone, Clean Slate, Heavy Metal, Skeleton Key, Good Year, Dead Weight, Signal Failure, Black Hole, Déjà Vu, Happy Accident). Ticket 18 found the binding constraint is London ore supply, not the outside-craft knobs. The chosen lever is lowering nameless demand (`civilianDemand`) for the pinned goods, so supply can meet it. A good hitting its cap occasionally is fine; the target is **up to 7 days of 30 pinned on average per good** (per seed 1–3, days 31–60). Report before/after tables for human sign-off.

Guard rails, all must still hold after the change: item named share 65–75%; factions still cover the majority of harvested ore (do not cut faction ore output or Independents' supply to compensate); no faction in permanent shortfall; turf and war endings healthy; sell-fee ladders and the flip-protection test unchanged. Data changes only unless the sim shows data cannot reach the target; if a code or recipe change looks needed, stop and ask. Goods with no crafter at all may need their demand cut to near zero; say so in the report instead of inventing a crafter.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/market.json` (per-good `civilianDemand`, `normalStock`), `scripts/sim_faction_economy.gd` and `scripts/sim_faction_economy_impl.gd` (run seeds 1–3: `godot --headless -s scripts/sim_faction_economy.gd -- days=60 seed=N every=0`, isolated user data folder), `.scratch/london-market/balance-report.md` (tickets 14 and 18 for the pinned lists and failed knobs), `.scratch/london-market/story-audit.md` (story 89), `docs/REFERENCE.md` §3.13 (update pinned values/demand table), `tests/test_market.gd` (data-pinned values, if any assert demand).

**Status:** ready-for-agent

- [ ] Sim seeds 1–3, days 31–60: average pinned-at-max days per good is ≤7 of 30, and no good is pinned for the whole window unless it has no crafter and the report says so
- [ ] Item named share stays 65–75%; factions' share of harvested ore does not fall; no new permanent faction shortfall; turf healthy
- [ ] Before/after table appended to `balance-report.md` (pinned days per good, named share, shortfall days, wallet growth)
- [ ] REFERENCE.md §3.13 matches the new demand values
- [ ] Full test suite and `scripts/check_all.sh` clean (the known `full_playthrough_tutorial_economy_ticks_and_save_roundtrip` failure excepted)
- [ ] Human sign-off on the report

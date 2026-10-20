# 16 — Prologue playtest + cut pass

**What to build:** The owner plays the full Prologue on device with the debug timing log on, exports the timing CSV, and decides what to cut toward ~30 min. Also settle the TBC numbers: emotion demand rise (+20% / 7 days placeholder), spar fee, cold-open lock threshold, guided-spar partner tuning. Cuts and retunes become follow-up tickets.

**Blocked by:** 15 — Prologue end-to-end test.

**Relevant files:** `systems/timing_log.gd` (CSV at `user://prologue_timing.csv`), debug app Timing log, `data/market.json` / Ticker op data, `data/combat_rounds.json`.

**Status:** ready-for-human

- [ ] Timing CSV captured for a full run.
- [ ] Cut list and retuned numbers written up as follow-up tickets.

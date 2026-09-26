# 13 — Full-act path test alongside Collective Act 2

**What to build:** An end-to-end test drives a save from two veins through Beat 7 via public entry points only (time, offers, contracts, events), with Collective Act 2 in progress, proving neither questline blocks the other. Includes the balance sanity check against live quotes and a final REFERENCE.md / CODEMAP.md consistency pass.

**Blocked by:** 11 — Beats 6–7: put it to work; 12 — Owen learns to craft

**Relevant files:** `tests/test_playthrough.gd` (prior art), `tests/test_collective.gd`, `tests/test_col_a2_*.gd`, `systems/offers.gd` (`quote_for_request`), `docs/REFERENCE.md`, `CODEMAP.md`; spec §"Testing Decisions", Further Notes.

**Status:** ready-for-agent

- [ ] Full act completes with Collective Act 2 in progress; Collective progression unaffected
- [ ] Owen reaches cultivating 2, never above 3, across the run
- [ ] Two realistic recurring contracts yield a positive weekly player share after Owen's wage (live quotes)
- [ ] REFERENCE.md §2 / §3.8 / §3.10 and CODEMAP.md match shipped behaviour
- [ ] Full suite + `scripts/check_all.sh` clean

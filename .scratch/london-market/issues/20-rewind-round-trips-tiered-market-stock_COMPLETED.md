# 20 — Rewind round-trips tiered market stock

**What to build:** A test proving that Rewind restores London market stock by tier exactly. Spec story 85 and "Testing Decisions" ask for a tiered stock change to round-trip through save **and** Rewind. Save is already covered; Rewind is not. Change tiered stock after a block opens, rewind to the block start, and assert every tier's stock, the per-tier supply tallies and prices are back to their block-start values (ints, not floats). If the test finds a real divergence, fix it and report it.

**Blocked by:** None — can start immediately.

**Relevant files:** `tests/test_rewind.gd` (add the case beside the existing block-rewind cases), `tests/test_savemanager.gd` (`tiered_item_stock_round_trips_through_save_as_ints`, prior art), `systems/rewind.gd` (`mark_block_start`, `rewind_to_block_start`), `systems/market.gd` (`record_supply`, `daily_reprice`), `.scratch/london-market/story-audit.md` (story 85), `.scratch/london-market/spec.md` ("Testing Decisions").

**Status:** ready-for-agent

- [ ] A test in the Rewind test file changes tiered stock for at least two tiers after the block start, rewinds, and asserts the market state equals its block-start copy
- [ ] The test asserts tier stock and per-tier supply tallies are ints after the rewind
- [ ] Test sets state directly and has no unbounded loops
- [ ] Test passes alone under `timeout 60`, then in the full suite

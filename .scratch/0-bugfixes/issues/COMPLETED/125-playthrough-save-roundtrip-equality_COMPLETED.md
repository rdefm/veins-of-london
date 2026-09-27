# 125 — Fix playthrough save/load equality

**What to build:** Diagnose and fix `test_playthrough.gd`'s
`full_playthrough_tutorial_economy_ticks_and_save_roundtrip` failure. A
manual-slot JSON round trip must restore the exact pure state tree produced
by the playthrough, including numeric types and persisted nested fields.

**Blocked by:** None.

**Relevant files:** `tests/test_playthrough.gd`, `autoload/SaveManager.gd`,
`docs/REFERENCE.md` §2 and §6.

**Status:** ready-for-agent

- [x] A narrow reproducible comparison identifies the first differing state path.
- [x] Save/load restores that persisted value and type exactly.
- [x] Regression coverage passes; full suite green.

## Comments

2026-09-16: Full isolated suite: 2458 passed, 1 failed. The sole failure is
this playthrough save-roundtrip assertion; it predates token-diet ticket 05
and is unrelated to comment removal. Earlier ticket 124 recorded the same
failure.

2026-09-18: A scratch diagnostic (deep-diffing `pre_save` against post-load
`GameState.state`, not checked in) isolated the first divergence to
`state.sales.pendingOffers[0].quote.lines[]`: `SaveManager._restore_int_types()`
only restored `unitValue`/`liveValue`/`payment`/`salesSkill` on a quote's
top level, never per `lines[]` entry, so a JSON round trip left each line's
`unitValue`/`liveValue` as floats. Writing the regression test (modeled on
`tests/test_offers.gd`'s mixed-offer case) surfaced two more instances of
the same gap in the same function: `offer.extraTypeDeadlineDays` and
`request.types[].qty` (mixed-request per-line quantity) were also never
restored. Fixed all three via two shared helpers
(`_restore_request_int_types`, `_restore_quote_int_types`) now called from
both the `pendingOffers` and `activeContracts` loops. A code-review pass
then flagged that `sales.contractHistory` entries — each a full standalone
copy of a settled contract + settlement (`systems/contracts.gd`'s
`settle()`), not a reference into `activeContracts`/`settlements` — were
never passed through `_restore_int_types()` at all, so the same fields
(plus `contract.delivered`/`settlement.delivered` unit-count dicts) would
float-round-trip there too; fixed with two more shared helpers
(`_restore_contract_int_types`, `_restore_settlement_int_types`), now
reused across `activeContracts`, `settlements`, and `contractHistory`.
`tests/test_savemanager.gd` gained one new case covering offer → contract →
settled contractHistory round-tripping exactly, ints included. Full suite:
2474 passed, 0 failed.

# 07 — Extract sell/trade modal family

**What to build:** The selling and trading modals — Archie sell menu, faction sell/buy menu, sell-vein quote, Nadia supply, craft-components menu — and the row builders they share (sell row, buy ore row, sell/buy vein row, sell sections) move to the modal registry. Shared row builders live in one helper script in the modals directory, not duplicated per modal. Quoting, acceptance, cancel-with-sellState-reset and the vein-trade flows behave exactly as now.

**Blocked by:** 06 — Modal registry + result modals extracted.

**Relevant files:** `scenes/components/modal_layer.gd`, `scenes/modals/`, `systems/economy.gd`, `systems/offers.gd`, `systems/vein_trade.gd`, `systems/collective.gd` (Nadia supply), `tests/test_modal_layer.gd`, `tests/test_vein_trade.gd`, `tests/test_economy.gd`, `tests/test_collective.gd`, `CODEMAP.md`. Mechanics untouched — REFERENCE.md selling / faction-trade sections only if a test needs re-reading.

**Status:** ready-for-agent

- [ ] Every sell/trade modal renders and behaves identically (rows, quantities, quotes, confirm/cancel, sellState cleared on cancel).
- [ ] No row-builder function is defined in more than one place.
- [ ] Modal layer no longer contains any sell/trade builder; syntax check and full test suite green.

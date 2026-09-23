# 05 — Vein buy/sell prices 5x higher

**What to build:** Buying a vein and selling a vein both cost or pay 5x the current amount. That covers the faction lane and Archie's marked-up price, which derives from the same quote. Nothing else changes: claim fees, security/guard costs, upkeep and ore prices stay as they are.

The base quote is `VeinTrade.quote()`, scaled by `veinSaleBaseUnits` (currently 35). Raising it to 175 scales every vein buy/sell path together. Check first that no non-price caller relies on that key.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `data/vein_growth.json` (`veinSaleBaseUnits`)
- `systems/vein_trade.gd` (`quote`), `systems/economy.gd` (`get_archie_vein_price`, `execute_sale` vein items), `systems/vein_list.gd`
- `scenes/screens/map.gd` (`_build_buy_vein_button`), `scenes/modals/sell_menu_view.gd`
- REFERENCE.md (add/update the vein sale-price row)
- `tests/test_vein_trade.gd`

**Status:** ready-for-agent

- [ ] Vein buy price and sell price (faction and Archie) are 5x their previous values for the same vein state
- [ ] Claim fees, security costs and ore prices unchanged
- [ ] REFERENCE.md reflects the new constant
- [ ] Price tests updated and passing

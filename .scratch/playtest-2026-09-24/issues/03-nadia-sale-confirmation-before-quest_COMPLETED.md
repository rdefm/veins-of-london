# 03 — Nadia vein sale: confirmation before quest narrative

**What to build:** When selling a vein to Nadia completes the "sell her a vein" Collective beat, the sale confirmation shows first, on its own. Dismissing it then plays the quest image/narrative, which stays up until the player dismisses it. Today the quest beat renders behind the confirmation, and dismissing the confirmation also wipes the quest beat (sale result close routes to Phone home).

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/sell_vein_quote_modal.gd`, `scenes/modals/sale_result_modal.gd`, `scenes/components/modal_layer.gd`, `scenes/modals/modal_registry.gd`, `systems/modal.gd`, `systems/vein_trade.gd`, `systems/collective.gd`, `systems/events.gd`, `data/events/col_a1_nadia_done.json`.

**Status:** ready-for-agent

- [ ] Sale confirmation shows alone; quest beat not visible behind it
- [ ] Dismissing confirmation surfaces the quest beat; it persists until its own dismiss/choice
- [ ] Non-quest vein sales unchanged (close still routes as before)
- [ ] Test: quest-triggering sale queues the event after the sale result, not concurrently

# 03 — Recipe-seller Trade sheet mode

**What to build:** The 🤝 Trade button on James's contact card and on Wren's key-member card opens the existing Trade sheet in a new recipe-seller mode. It is buy-only, with a single Recipes category, and rows are grouped by recipe. Each row shows the rung, the rank ceiling it raises to, the discounted price and its state: owned / buyable / locked with reason / master "not for sale". Confirming calls `RecipeKnowledge.buy` per selected row. Nothing goes to the Bag; the purchase shows on the lab recipe page at once. Before the seller is unlocked, the button shows the existing "not unlocked yet" locked form. The Guild Marketplace faction shop is unchanged.

Spec: `.scratch/recipe-acquisition/spec.md` § Implementation Decisions — "Trade sheet recipe-seller mode"; § User Stories 34–37, 50–51.

**Blocked by:** 02 — Sellers, gates, prices and buying knowledge.

**Relevant files:**
- `scenes/modals/sell_menu_view.gd` (existing Archie / Collective contact / faction shop modes), `scenes/modals/sell_menu_modal.gd`, `scenes/modals/modal_layer.gd`
- `scenes/components/contact_cards.gd` — James card (~l.335), `build_key_member_card` (~l.488), `build_trade_action` (~l.177)
- `systems/recipe_knowledge.gd` (read-only queries + `buy`)
- `scenes/components/item_icons.gd` (recipe icons)
- `tests/test_contact_cards.gd`; new smoke test for the mode
- `CODEMAP.md` (sell_menu_view row)

**Status:** ready-for-agent

- [ ] James's and Wren's cards each have a Trade button that opens recipe-seller mode for that seller only. It's locked before their unlock flag.
- [ ] Rows list only that seller's recipes (per `seller_of`), grouped by recipe, with rung, new ceiling, price, state and lock reason.
- [ ] Owned and master rows can't be selected. Confirm calls `buy` for each selected row; the screen never mutates state.
- [ ] Smoke test: mode builds for both sellers and confirm calls `buy` (cash drops, rung exact).
- [ ] Guild Marketplace shop behaviour unchanged (existing tests pass).
- [ ] On-device QA block in report.

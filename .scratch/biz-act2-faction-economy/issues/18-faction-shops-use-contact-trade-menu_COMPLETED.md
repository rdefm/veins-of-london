# 18 — Faction shops use the contact Trade menu

**What to build:** The Guild marketplace and the Firm, Network and Conclave shops open the same Trade menu that Collective contacts use (the `sell_menu` modal: sell/buy toggle, Ore/Items/Veins tabs, review step, sale result), instead of the separate `FactionShopScreen` card list. Opening from a map shop pin or the Guild's faction card opens the modal for that faction with no contact attached.

Decision from the human after ticket 02 ("trade menus should match the trade option for contacts"). Not in the original spec.

**Blocked by:** 02 — Faction shop pins (done).

**Relevant files:**
- `scenes/modals/sell_menu_view.gd`: header kicker assumes a contact (`Contacts.display_name(contactId || "des")`), "Buy from contact" label, `_confirm()` always calls `Collective.complete_trade(contactId)`. It needs a faction-only path: kicker = faction name, "Buy from <shortName>", confirm → `Economy.sell_to_faction_from_sell_state(faction_id, "")` + `sale_result` modal, no bark/contact relation
- `scenes/modals/sell_menu_modal.gd`, `scenes/components/modal_layer.gd` (sell_menu routing)
- `scenes/components/map_canvas.gd` `_activate_pin` (`guild_marketplace` / `faction_shop` kinds → `Modal.open("sell_menu", { "factionId": id, "contactId": "" })`)
- `scenes/components/contact_cards.gd` ~line 703 (Guild faction card "Guild Marketplace" button)
- `scenes/screens/faction_shop.gd` + `scenes/Main.gd` (`FACTION_SHOP_SCREENS`): retire or reduce to the locked state
- `systems/economy.gd` `sell_to_faction_from_sell_state`, `can_buy_from_faction`
- Tests: `tests/test_faction_shop_screen.gd` (rewrite/retire), `tests/test_map_canvas.gd` pin activation cases, sell-menu view tests
- CODEMAP rows for faction_shop.gd / sell_menu_view.gd / map_canvas.gd; REFERENCE §3.6a "Shop pins"; M1.5-NETWORK-MAP pin list

**Open questions (ask the human before building):**
1. The shop screen lets you **buy consumables** from a faction's holdings; the Trade menu hides Items on the buy side. Add item buying to the Trade menu, or drop consumable buying from shops?
2. The Trade menu's **Veins tab** buys faction-held veins (`Sites.sites_with_faction_vein`). Should Guild/Firm/Network/Conclave shops expose vein buying too, or only ore/items?
3. **Guild non-member:** the pin currently opens a "Guild members only" page. Keep a locked page, show a short modal/toast, or hide the pin until joined?

**Decisions (human, 2026-09-29):** 1. add item buying (shop mode only; Collective contacts unchanged). 2. Veins tab shown. 3. Guild pin + faction-card button hidden until joined.


- [x] Guild, Firm, Network, Conclave shop entry points (map pins + Guild faction card) open the contact-style Trade menu for that faction
- [x] Faction-only trade: header shows the faction, buy toggle names the faction, confirm settles against that faction's holdings/cash with no contact bark or contact relation change
- [x] Prices, stock and qty ceilings match what `FactionShopScreen` showed (same `Economy.get_faction_*` calls)
- [x] Collective contact Trade behaviour unchanged
- [x] Open questions 1–3 resolved and implemented as decided
- [x] Human on-device check listed in the report (each pin opens the menu, buy/sell/review works, Guild locked behaviour)

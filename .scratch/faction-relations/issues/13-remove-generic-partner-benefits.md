# 13 — Remove generic Partner benefits

**What to build:** The faction perks replace the generic Partner layer. Remove the Partner price favour and the passive `defenceHelp`/`raidHelp`. Partner trouble asks stay (they're favours), and so do warnings (now the Network perk). Must ship in the same release as the perks.

**Blocked by:** 08, 09, 10, 11, 12

**Relevant files:** `systems/partners.gd` (`can_ask_price_favour`, `ask_price_favour`, help terms), `systems/raiding.gd`, partner config in `data/factions.json`, `scenes/components/contact_cards.gd` (price-favour button), `autoload/SaveManager.gd` (drop stale state), `tests/test_partners.gd`. REFERENCE.md §3.10 "Partners", §1.11.

**Status:** ready-for-agent

- [ ] Price favour, `defenceHelp` and `raidHelp` are gone from code, data and UI
- [ ] Trouble asks and warnings still work; partner tests updated
- [ ] Old saves with price-favour state load cleanly
- [ ] REFERENCE §3.10 updated

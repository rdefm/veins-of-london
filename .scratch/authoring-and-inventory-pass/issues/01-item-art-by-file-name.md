# 01 — Item art found by file name

**What to build:** Dropping a PNG named after a recipe key into the item art folder makes that art appear everywhere the item's icon shows, with no data edit. Lookup order: convention path, then the recipe's `icon`, then the symbol.

**Blocked by:** None — can start immediately

**Relevant files:** `scenes/components/item_icons.gd`, `tests/test_item_icons.gd`, `assets/items/` (new), `docs/adr/0003-app-icon-asset-contract.md`, `docs/adr/0005-event-image-asset-contract.md`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Convention path wins when the file exists
- [ ] Falls back to the recipe's `icon`, then to the symbol
- [ ] No data edit is needed for new art to appear
- [ ] Tests cover all three lookup outcomes

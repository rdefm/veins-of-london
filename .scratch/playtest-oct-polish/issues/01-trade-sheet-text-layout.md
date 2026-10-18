# 01 — Trade sheet text layout fixes

**What to build:** Text on the Trade sheet must wrap or truncate normally rather than rendering one character per line or overlapping other text. Known cases, all seen in playtest screenshots:
- Buy/Ore tab: the "Sold out" label renders one character per line down the right edge of each row.
- Sell goods/Items tab: the red "N selected" badge renders vertically ("2 6 s e l e c t e d"). In the expanded tier rows, the "Tier N" label and the price line overlap the item name and the "N tiers · N in stock" line.
- James's recipe seller, "Master technique · rank 5": the lock text "Not for sale. Someth…" renders one character per line, taking most of the screen.

Sweep every Trade mode (Archie, Collective contact, faction shop, recipe seller, guard kit, which shares the pattern) and every category tab (Ore/Items/Veins/Recipes), sell and buy, collapsed and expanded rows. Fix the root cause in the shared row builder: most likely a label with no minimum width given autowrap inside a squeezed container. Don't patch each label separately.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/sell_menu_view.gd`, `scenes/modals/guard_kit_view.gd`, `scenes/modals/sell_menu_modal.gd`, `data/recipe_knowledge.json` (lock text), `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] "Sold out", "N selected" and recipe lock text read horizontally at phone width (shortest common phone width included)
- [ ] Expanded item tier rows: tier label, price line, name and stock line never overlap
- [ ] Every Trade mode and tab checked; the human is given an on-device checklist

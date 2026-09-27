# 134 — Contract card: one-off/weekly pip + ore glyphs

**What to build:** Offer cards and active contract cards in BizBrief tell one-off and recurring apart at a glance with a label pip ("ONE-OFF" / "WEEKLY"). Each card shows the ore-type glyph(s) for what it asks for: one glyph per requested ore type on mixed contracts. Item/consumable requests show the glyph of that item's ore type, looked up from item/recipe data, not hardcoded. Uses the existing ore glyph set and palette per ui-vision.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/contract_card.gd`, `scenes/components/ore_glyphs.gd`, `scenes/components/symbol_glyph.gd`, `scenes/phone_apps/bizbrief_app.gd`, `systems/contracts.gd` (`request_lines`), item/recipe data under `data/`, `docs/ui-vision.md`.

**Status:** ready-for-agent

- [ ] Pip on every offer + active card, correct per `contractType`
- [ ] Correct glyphs for ore, mixed and consumable requests (the request → ore types helper is unit-tested)
- [ ] Human on-device: check a one-off ore offer, a weekly ore contract, a timePearl contract and a mixed contract

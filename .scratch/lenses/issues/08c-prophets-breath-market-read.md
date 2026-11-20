# 08c — Prophet's Breath market read

**What to build:** A second source for 08a's insight slot. While the player's Prophet's Breath effect is active outside combat (same duration as today — no lens needed), every market row's `!` turns **light red** and is tappable; tapping shows tomorrow's projected price as a band: "If you do nothing, tomorrow this will sell for £a–£b."

- Band centred on 08a's projection (includes the player's trades so far today). Width by Breath level (the effect's item tier), placeholder ±20% / ±15% / ±10% / ±7% / ±5% for levels 1–5, in data (follow the `data/lab.json` prophetsBreath per-level table pattern).
- Rows whose projected move is ≥ 5% go **bright red + pulsing** (08a's notable state); all rows are tappable while Breath runs.
- Breath and Fate lines sit together in the same bubble; neither overrides the other.
- Accepted: the band can miss (rollover steps before the reprice are unseen).
- Strings in data; PROSE-REVIEW.

**Blocked by:** 08a — Market insight `!` + Fate gut feeling.

**Relevant files:**
- `systems/active_effects.gd` (`find`, `prophets_breath_active`, effect `level`)
- `systems/lab.gd` (`breath_row` — per-level table pattern), `data/lab.json` (`prophetsBreath`)
- `systems/market.gd` (08a's projection)
- 08a's insight slot + the market screen(s) it lands on (`scenes/phone_apps/ticker_app.gd` / `scenes/modals/sell_menu_view.gd`)
- `scenes/modals/active_effects_modal.gd` (effect text, if Breath's description should mention the market)
- `tests/test_active_effects.gd`, `tests/test_market.gd`
- `docs/ui-vision.md` (palette), `docs/CONTENT-GUIDE.md`
- REFERENCE §3.13 London market

**Status:** ready-for-agent

- [ ] Breath active → every row light red and tappable with a £ band; inactive → no Breath lines.
- [ ] Band contains the projection; width follows Breath level.
- [ ] Notable rows (≥ 5%) pulse whether Breath, Fate or both flag them; both sources' lines show together.
- [ ] Projection still writes nothing.
- [ ] REFERENCE §3.13, CODEMAP updated; syntax check clean, tests pass; strings flagged PROSE-REVIEW.

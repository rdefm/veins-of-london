# 09 — Make market glyphs readable on charcoal

**What to build:** Ore and item identifying glyphs use a light Ticker colour on dark Stock Market rows and the dark price-detail surface. The screenshot shows near-black glyphs against charcoal.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/ticker_app.gd`; `scenes/components/symbol_glyph.gd`; `scenes/components/ui.gd`; `tests/test_symbol_glyph.gd`; `tests/test_ticker_stock_filters.gd`; `docs/ui-vision.md` §10 Family 2.

- [ ] Every canonical ore and item glyph is distinguishable on Stock Market rows and price detail, including drawn fallback glyphs.
- [ ] Glyph colour follows Ticker's dark-surface palette without changing symbols or their market order.
- [ ] Headless checks inspect rendered glyph colour; on-device QA confirms contrast at phone size.

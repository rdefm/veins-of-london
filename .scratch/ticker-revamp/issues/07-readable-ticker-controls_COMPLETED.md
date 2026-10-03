# 07 — Restore labels and symbols on Ticker controls

**What to build:** Stock Market ore-type and In stock filters, plus Ticker action and navigation buttons, display their labels and selection symbols in readable contrast. The screenshot shows six outlined filter targets with no visible content.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/ticker_app.gd`; `scenes/components/contact_cards.gd`; `tests/test_ticker_stock_filters.gd`; `tests/test_ticker_news.gd`; `docs/ui-vision.md` §10 Family 2; `.scratch/ticker-revamp/ticker-concept.html`.

- [ ] Every ore filter shows its ore name and on/off mark; In stock shows its label and on/off mark on the dark Stock Market surface.
- [ ] Ticker action, close, and navigation controls show readable text or symbols on both dark and paper surfaces, including disabled states.
- [ ] Existing filter behaviour remains intact; headless checks cover effective text and symbol contrast, with on-device checks at narrow width.

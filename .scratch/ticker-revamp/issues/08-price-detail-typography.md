# 08 — Align price detail typography with The Ticker

**What to build:** An opened ore or item uses The Ticker's dark market typography and hierarchy. The current detail screen still shows the older heading, body, and boxed-card treatment in the screenshot.

**Blocked by:** 04 — Inspectable price detail and market notes; that ticket establishes the final detail layout this styling must fit.

**Status:** ready-for-agent

**Relevant files:** `.scratch/ticker-revamp/issues/04-inspectable-price-detail.md`; `scenes/phone_apps/ticker_app.gd`; `scenes/components/ui.gd`; `tests/test_ticker_stock_filters.gd`; `docs/ui-vision.md` §10 Family 2; `.scratch/ticker-revamp/ticker-concept.html`.

- [ ] Ore and item detail views show a legible name, quote, daily move, chart heading, annotations, and demand information with Ticker-consistent type sizes, colours, and spacing.
- [ ] The detail remains readable at narrow phone width and preserves live market values, notes, scrolling, and Back behaviour.
- [ ] Headless presentation checks and a short on-device comparison against the approved Ticker concept pass.

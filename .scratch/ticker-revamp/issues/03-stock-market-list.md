# 03 — Stock Market list with its existing controls

**What to build:** The Stock Market tab adopts the concept's compact market brief and divided price rows while retaining the full live market, ore-type and In stock filters, collapsible Ore/Items sections, and demand information.

**Blocked by:** 01 — Branded News feed and story order.

**Status:** ready-for-agent

**Relevant files:** `.scratch/ticker-revamp/ticker-concept.html`; `scenes/phone_apps/ticker_app.gd`; `scenes/components/ui.gd`; `systems/market.gd`; `data/market.json`; `data/barometer.json`; `tests/test_ticker_stock_filters.gd`; `tests/test_market.gd`; `docs/REFERENCE.md` §3.13 London market and §3.2 Barometer; `docs/ui-vision.md` §10 Family 2; `CODEMAP.md`.

- [ ] Demand Watch shows every live demand modifier or the existing no-modifier state; it never uses the concept's canned sample text.
- [ ] Ore and Items show **all** canonical market goods in market order, with live lot price, yesterday's direction and £ move, readable name/type, and the existing symbol or an equivalent identifying treatment.
- [ ] All five ore-type toggles and In stock still work together. An item remains visible when any selected ore type is among its recipe ingredients. Empty results are explained.
- [ ] Ore and Items headers still collapse/expand independently and keep their view state across refreshes. Tapping a visible good still opens its detail; changing News/Stock Market tabs remains usable.
- [ ] Existing filter/collapse tests and new presentation checks pass headlessly with Godot 4.7; provide a short on-device QA list.

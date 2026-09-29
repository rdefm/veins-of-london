# 04 — Stock Market tab + ▲/▼ on sell rows

**What to build:** The Ticker app splits into two tabs. **News** keeps the existing headlines and axis push/pull/influence actions unchanged. **Stock Market** (visible from day 1) lists each ore type then each item: symbol, name, price, ▲/▼ + delta vs yesterday, plus a list of active Ticker demand modifiers. Tapping a row opens a price chart over the stored history with annotation markers, and the item's active demand modifier (or, for an ore, the items currently driving its demand). Market records annotations (bounded list): Ticker state shift affecting a good; player single-day supply above a threshold × normal volume ("dump"); day move beyond a threshold ("spike" / "crash") — each with day, good, kind, source. Every sell row in every lane shows ▲/▼ vs yesterday. Screens only read state/Market; they mutate nothing.

**Blocked by:** 03 — Ticker drives item demand.

**Relevant files:**
- `scenes/phone_apps/ticker_app.gd` (+ its scene)
- `systems/market.gd` (annotations, yesterday's price read, "items driving this ore" read)
- Sell-row screens: Archie lane / faction lane screens, `scenes/phone_apps/bizbrief_app.gd` where prices show
- Market JSON (annotation thresholds, annotation cap)
- `tests/test_market.gd` (annotation recording through rollover)
- `docs/ui-vision.md` (styling), `CODEMAP.md` (ticker_app row), `docs/REFERENCE.md` Market section (annotations)

**Status:** ready-for-agent

- [ ] Rollover tests: Ticker shift, dump and spike/crash each append a bounded annotation with day/good/kind/source
- [ ] Ticker app has News (unchanged behaviour) and Stock Market tabs; Stock Market available day 1
- [ ] Rows show price and ▲/▼ + delta; chart with annotation markers; active modifiers listed
- [ ] Sell rows in every lane show ▲/▼
- [ ] PROSE-REVIEW: tab labels, annotation labels, modifier strings flagged in report
- [ ] On-device check block listed for the human

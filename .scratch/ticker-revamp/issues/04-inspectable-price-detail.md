# 04 — Inspectable price detail and market notes

**What to build:** A Stock Market good opens the concept's price-detail layout, using actual market history. Tapping a plotted day shows that day's recorded quote. Existing annotations and demand explanations remain available below the chart.

**Blocked by:** 03 — Stock Market list with its existing controls.

**Status:** ready-for-agent

**Relevant files:** `.scratch/ticker-revamp/ticker-concept.html`; `scenes/phone_apps/ticker_app.gd`; `scenes/components/line_chart.gd`; `systems/market.gd`; `data/market.json`; `tests/test_market.gd`; `tests/test_phone_bizbrief.gd`; `docs/REFERENCE.md` §3.13 London market; `CODEMAP.md`.

- [ ] Every ore/item detail shows its live quote, unit/lot, yesterday move, and all available recorded price days. No synthetic 28-day chart or sample numbers appear; early-game and empty-history states are clear.
- [ ] Tapping or dragging to a plotted day selects a real history point and displays its recorded day and quote; selection stays within available points and works at narrow phone widths.
- [ ] Chart event markers and the complete newest-first annotation list remain legible, including same-day multiple events. Ore shortage drivers and item Ticker demand details remain available and truthful.
- [ ] Back returns to the filtered/collapsed market list without resetting its view choices. Any shared chart changes leave BizBrief charts working.
- [ ] Headless tests verify history-point selection and existing detail data; Godot 4.7 checks pass. Provide on-device touch, chart, and scrolling QA steps.

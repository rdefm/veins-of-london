# 12 — Ticker Stock Market: real dates

**What to build:** The Stock Market tab in The Ticker shows "Day 81" / "D81" style labels. Replace them with the in-game date in the game's existing date format (as on the top board, e.g. "TUE 2 JUL"), including chart axis labels and selected-point quotes.

**Blocked by:** None — can start immediately

**Relevant files:** `scenes/phone_apps/ticker_app.gd` (`selectedQuote`, `noteDay` uses), `data/barometer.json` (`selectedQuote`, `noteDay`), `scenes/components/line_chart.gd` (`"D%d"` inspectable labels), `systems/calendar.gd` (`format_day`, `date_parts`)

**Status:** ready-for-agent

- [ ] No "Day N"/"DN" labels remain in the Stock Market tab
- [ ] Dates via `Calendar.format_day` (or a shorter data-driven variant if width demands)
- [ ] Chart labels fit at phone width
- [ ] Human checks Stock Market tab

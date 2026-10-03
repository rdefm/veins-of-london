# 06 — Restore visible News and Stock Market tabs

**What to build:** The Ticker shows readable News and Stock Market tab labels in its branded header. The current invisible labels still respond to taps; restore their visible selected and unselected states without changing tab navigation.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/ticker_app.gd`; `scenes/components/contact_cards.gd`; `tests/test_ticker_news.gd`; `tests/test_ticker_stock_filters.gd`; `docs/ui-vision.md` §10 Family 2; `.scratch/ticker-revamp/ticker-concept.html`.

- [ ] Both tab labels are readable on the dark header when News is selected and when Stock Market is selected; selected state remains clear.
- [ ] Tapping either visible tab still opens the correct content and survives a refresh.
- [ ] Headless checks inspect effective text styling in the themed phone, plus an on-device check at narrow phone width.

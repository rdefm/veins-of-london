# 10 — Restore an obvious return from News stories

**What to build:** After opening a News story, the reader has a visible, tappable way back to the News feed. The current story view appears to trap the reader despite an existing return route in code.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `scenes/phone_apps/ticker_app.gd`; `systems/phone_nav.gd`; `tests/test_ticker_news.gd`; `docs/ui-vision.md` §10 Family 2; `.scratch/ticker-revamp/ticker-concept.html`.

- [ ] A story displays an obvious Back or close control with readable contrast and a usable touch target on the paper article surface.
- [ ] Back and close return to the News feed; returning from Influence reaches the same story first, then the feed.
- [ ] Headless navigation checks and on-device checks cover a state story and a London Wire story.

# 01 — Branded News feed and story order

**What to build:** Opening The Ticker shows the concept's editorial header and News feed inside the existing phone frame. The live political, economic, and social stories sit under **World News**, **The Economy**, and **London Life**; **London Wires** remains a separate newest-first section. The axis whose active state changed most recently leads the feed and gets the featured-story treatment. A story opens the existing axis detail until ticket 02 replaces that route.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/ticker-revamp/ticker-concept.html`; `scenes/phone_apps/ticker_app.gd`; `scenes/screens/phone.gd`; `scenes/components/phone_device_shell.gd`; `systems/barometer.gd`; `autoload/GameState.gd`; `autoload/SaveManager.gd`; `data/barometer.json`; `data/palette.json`; `tests/test_barometer.gd`; `tests/test_phone_device_shell.gd`; `docs/M1-LONDON.md` §D4.5; `docs/REFERENCE.md` §2 STATE SCHEMA and §3.2 Barometer; `docs/ui-vision.md` §10 Family 2; `CODEMAP.md`.

- [ ] Concept branding, typography, spacing, dividers, featured story, category headings, and News/Stock Market tabs appear within the existing device shell; no second phone frame or sample story/price data is added.
- [ ] The three current active-state stories use live labels, headlines, descriptions, and rumblings. London Wires retains every existing entry, newest first, with an empty state when there are none.
- [ ] Only an **active-state change** updates an axis's recency, including one caused by manual Push. Routine progress changes do not. The newest axis leads; ties and old saves use the approved base order: World News, The Economy, London Life. London Wires follows those sections.
- [ ] Recency is saved as pure state, documented in `docs/REFERENCE.md`, and backfilled safely for existing saves. Existing Ticker rumblings badges and story navigation still work.
- [ ] Update the Ticker visual exception in `docs/ui-vision.md`; update `CODEMAP.md` if ownership changes. Headless checks and tests pass with Godot 4.7; provide a short on-device visual QA list.

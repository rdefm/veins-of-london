# 13 — Ore Regulation no longer raises mugging risk

**What to build:** When Ore Regulation is the active political barometer state, it continues to increase demand for every crafted item but no longer changes mugging chance. Remove the existing 10-percentage-point mugging modifier without changing other barometer states.

**Blocked by:** None — can start immediately. Blocks 05 — Full state and London Wire articles.

**Status:** ready-for-agent

**Relevant files:** `docs/REFERENCE.md` §1.9 `data/barometer.json`, §3.2 Barometer; `data/barometer.json`; `systems/barometer.gd`; `scenes/phone_apps/ticker_app.gd`; `tests/test_barometer.gd`; `.scratch/ticker-revamp/ticker-state-prose-draft.md`; `CODEMAP.md`.

- [x] Canonical rules and state data remove Ore Regulation's `mugChance` effect while retaining its existing crafted-item demand modifier.
- [x] Headless tests confirm Ore Regulation does not change effective mugging chance, including when combined with another active state that does; its item-demand effect still applies.
- [x] Ore Regulation's description, headlines, Ticker impact display, and approved article prose do not claim that the state raises mugging risk or guarantees a higher market quote.
- [x] Godot 4.7 syntax checks and the full headless test suite pass. The report identifies an on-device Ticker impact check.

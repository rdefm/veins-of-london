# 05 — Full state and London Wire articles

**What to build:** Replace interim short article copy with complete editorial deck/body text for all 15 barometer states and every existing London Wire event type. Keep titles, subjects, game-impact facts, and prices tied to live canonical data. This content ticket follows the working app tickets.

**Blocked by:** 02 — News articles and same-axis Influence modal; 04 — Inspectable price detail and market notes.

**Status:** ready-for-agent

**Relevant files:** `.scratch/ticker-revamp/ticker-concept.html`; `data/barometer.json`; `data/constants.json`; `systems/barometer.gd`; `systems/factions.gd`; `systems/faction_ai.gd`; `systems/raiding.gd`; `scenes/phone_apps/ticker_app.gd`; `tests/test_barometer.gd`; `docs/CONTENT-GUIDE.md` §§3–4; `docs/REFERENCE.md` §1.9 `data/barometer.json`, §2 STATE SCHEMA, §3.2 Barometer, and §3.13 London market; `CODEMAP.md`.

- [ ] All 15 state articles have a coherent deck and flavour body for the headline variant shown. New prose lives in data, follows the Content Guide, and is listed under `PROSE-REVIEW:` in the implementation report.
- [ ] Every existing London Wire source has a suitable article body with live faction, ore, district, and day details where relevant. Structured source details may be added to new wire entries; old `{day, text}` saves still show a readable fallback.
- [ ] Impact copy states only effects established by `docs/REFERENCE.md` and current game data. No sample concept values, invented mechanics, or misleading guaranteed market outcomes are used.
- [ ] Headless checks validate article lookup/template coverage and formatting for every state and wire source. Godot 4.7 checks and the full test suite pass; provide an on-device prose/layout review list.

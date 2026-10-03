# 02 — News articles and same-axis Influence modal

**What to build:** Tapping a state story opens the concept's article sheet with its live headline, game impact, and current short description as interim flavour text. Its **Influence** button opens actions for that story's axis directly. London Wires opens a read-only article sheet using its existing text and date; ticket 05 supplies full prose later.

**Blocked by:** 01 — Branded News feed and story order.

**Status:** ready-for-agent

**Relevant files:** `.scratch/ticker-revamp/ticker-concept.html`; `scenes/phone_apps/ticker_app.gd`; `systems/phone_nav.gd`; `systems/barometer.gd`; `systems/modal.gd`; `scenes/components/modal_layer.gd`; `data/barometer.json`; `tests/test_barometer.gd`; `tests/test_phone_nav.gd`; `docs/M1-LONDON.md` §D4.5; `docs/REFERENCE.md` §1.9 `data/barometer.json`, §2 STATE SCHEMA, and §3.2 Barometer; `CODEMAP.md`.

- [ ] Tapping an axis headline opens an article sheet within the phone frame. The article uses the current state's headline/description and a truthful impact summary derived from canonical effects; it never copies the concept's sample mechanics or static impact figures.
- [ ] **Influence** opens a modal for that article's axis without an intervening three-axis chooser. It shows all that axis's state progress bars, £2,000 Push/Pull with current holdings and cooldown/affordability disabling, plus the existing greyed M4 actions and full costs.
- [ ] Performing Push/Pull refreshes live state and preserves the intended return path to the article and feed. Closing either sheet, using Back, and leaving the app remain reliable; no game state is mutated directly by the screen.
- [ ] Every London Wire remains readable and can open a read-only article using its saved text/day. Wires do not offer Influence or claim an unrecorded game effect; old saves still display them.
- [ ] Headless tests cover article-to-axis routing and action availability, including cooldown and insufficient cash. Godot 4.7 checks pass; provide on-device modal and back-navigation QA steps.

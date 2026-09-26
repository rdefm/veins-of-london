# 02 — Particulars and inline floorplan

**What to build:** Opening any other property's listing shows the approved estate agent particulars view: large property photo, name/location, rent and buy terms, room count, calculated raid risk, and existing listing copy. The existing Rent and Buy actions remain at the end of the details, with their affordability and move-loss information. If a tier has a floorplan, show the existing static plan inline below the copy while scrolling; currently only Flat has one. Tiers without a plan show no empty plan section.

**Blocked by:** 01 — Estate agent listings and brand chrome.

**Status:** ready-for-agent

**Relevant files:** `.scratch/harrows-redesign/spec.md`; `.scratch/harrows-redesign/harrows-mockup.html`; `scenes/phone_apps/property_app.gd`; `scenes/components/floorplan_view.gd`; `data/home.json`; `data/floorplans.json`; `assets/floorplans/flat.svg`; `tests/test_phone_property.gd`; `tests/test_hq_floorplan.gd`; `docs/REFERENCE.md` tier data before §2.2, §3.3 Home; `docs/hq-diorama-vision.md` §7; `CODEMAP.md`.

- [ ] Studio and Flat particulars match the approved mockup's layout and Harrow's brand styling; all other tiers use the same presentation with their own existing data and photos/fallbacks.
- [ ] Flat's static floorplan is visible inline below its particulars copy when scrolling; Studio and every tier without a plan omit the section. No room editing is offered in Harrow's.
- [ ] Rent, Buy, affordability disabled state, utilities preview, room-wipe warning, conditional security/guard losses, and back-to-listings behaviour remain correct for upward and downward moves.
- [ ] No search, filters, favourites, viewing requests, or other new property actions are introduced.
- [ ] Headless syntax check and all tests pass; property screen tests cover plan presence/absence and preserved move actions. Report concise on-device checks for detail scrolling, plan readability, and action reachability.

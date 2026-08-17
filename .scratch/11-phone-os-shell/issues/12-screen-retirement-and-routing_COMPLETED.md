# 12 — Screen retirement and routing cleanup

**What to build:** The final cutover — delete the `you`, `bag`, `inventory`, and `home` screens, reroute every call site that referenced them, and make sure old saves migrate safely instead of soft-locking.

**Blocked by:** 11 (dock restructure), 06 (Rest and home-raid trigger relocated to HQ)

**Status:** ready-for-agent

- [ ] `you`, `bag`, `inventory`, and `home` screen ids are deleted from the project
- [ ] Every call site that navigated to `home` now lands on the phone app grid
- [ ] Raid win/loss routing lands the player on phone home with the bag drawer already open, showing loot
- [ ] Every generic back-to-home affordance across the project routes correctly
- [ ] An old save whose `currentScreen` is set to any retired id (`you`, `bag`, `inventory`, `home`) loads onto the app grid, not the title screen
- [ ] The unknown-screen-id fallback (previously defaulting to `title`) explicitly maps retired ids to `home`
- [ ] In-app back navigation (e.g. Ticker's axis drill-down) uses the app's own in-app back, not a generic back-to-home call
- [ ] `home.gd`'s remaining content is audited before deletion and confirmed fully superseded (to-do card by Notes, Save & Load by the Save/Load app, Inventory button and stats card by the drawer and Profile) — anything found not to be superseded is flagged, not silently dropped
- [ ] Tests cover: save migration for each retired id, raid-win routing destination, at least one generic back-button call site

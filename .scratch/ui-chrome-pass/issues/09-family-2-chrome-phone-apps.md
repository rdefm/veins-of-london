# 09 — Apply Family 2 chrome: Phone home-grid + apps

**What to build:** Re-skin `scenes/screens/phone.gd` (home-grid app tiles,
SMS threads, James jobs) and `scenes/components/app_tile.gd` per the
Family 2 design spec from ticket 07 — the home grid, and each app's
list/detail views (Notes, Factions, The Ticker, Profile, Save/Load,
Notifications, Reynard's, Harrow's). Values, unlock-gating, and app logic
are unchanged — rendering pass only. Can run in parallel with ticket 08
once 07 lands (different files).

**Blocked by:** 07

**Status:** ready-for-agent

- [ ] Phone home grid and every listed app render per the Family 2 spec from ticket 07
- [ ] No amber/cream default-theme styling remains on the Phone tab or any app under it
- [ ] All existing app-unlock/lock badges and navigation behaviour unchanged
- [ ] `tests/test_phone_screen.gd` (or equivalent) updated for the new styling if it asserts on visuals

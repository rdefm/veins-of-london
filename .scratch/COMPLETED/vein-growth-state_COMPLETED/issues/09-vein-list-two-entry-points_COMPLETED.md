# 09 — Vein list, two entry points

**What to build:** a portfolio list of the player's veins with inline management, reachable two ways — scoped to a district from the VfL app's map, and scoped to everything from the HQ Vein Station room. Not a standalone phone app (deviates from the PRD's §6.2 default proposal — confirmed in review): the district bubble gets a "List view" option alongside its existing options, and the Vein Station room gets a "view and manage all veins" option once built.

**Blocked by:** 01 (core model), 06 (Vein Station target/assignment data to display), 08 (establishes the Cultivate/Prune/projected-yield button pattern this list reuses).

**Status:** ready-for-agent

- [ ] Shared vein-list component/screen: per row — district, ore type, terroir tier, growth bar with band label, days-until-wall, security tier, Vein Station assignment/target if any.
- [ ] Sort/filter at minimum by band, so "what needs me this week" is one tap.
- [ ] Inline actions Cultivate / Prune (light) / Prune (hard) / Manage, each routing through the same `Cultivating` functions and `Travel.ensure_district` call as the map sheet — convenience layer over existing rules, no second code path.
- [ ] Projected prune yield shown on the button before it's pressed (same rule as ticket 08).
- [ ] District entry point: `systems/district_bubble.gd`'s district options gain a "List view" option that opens the list filtered to that district's veins.
- [ ] HQ entry point: once the Vein Station room is built, it exposes an option to open the list unfiltered (all player veins across every district).
- [ ] Confirm no phone-app tile or `PhoneNav.APPS`/`PhoneApps.apps()` entry is added for this — the PRD's default proposal was superseded by the district+HQ design.
- [ ] `test_district_bubble.gd` (or equivalent) and a new test file for the list component covering row content, band filter, and that inline actions call the same `Cultivating`/`Travel` functions as the map sheet.
- [ ] `godot --headless -s scripts/check_runner.gd -- <file>` clean; `scripts/run_tests.sh` green.

**Human to check on-device:** district-scoped list matches what's on the map for that district; HQ list shows the full portfolio; inline actions from the list produce identical results to acting from the map sheet; band filter actually narrows the list.

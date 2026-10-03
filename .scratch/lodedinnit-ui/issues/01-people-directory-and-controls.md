# 01 — LodedInnit People directory and controls

**What to build:** Give LodedInnit its direction C identity inside the existing phone frame: prototype logo, plum/copper brand, consistent Feed/People tabs below the header, and a compact People directory grouped by enabled role. Each live candidate row shows name, headline, availability, level/cap and weekly wage and still opens the profile. Make Role, ore specialism and Wage controls work; omit the decorative `⋯` menu.

**Blocked by:** None — can start immediately.

**Relevant files:** `.scratch/lodedinnit/prototype-lodedinnit.html` (direction C, pane `01 · People`, `hybridPeople()`, `hybridTop()` and `.b`/`.c` styles); `.scratch/lodedinnit/lodedinnit-logo-prototype.png` and `.svg` (logo source); `.scratch/lodedinnit-ui/spec.md` §§Visual reference/People; `scenes/phone_apps/lodedinnit_app.gd` (directory/tabs); `scenes/screens/phone.gd`, `scenes/components/phone_device_shell.gd` (phone mount); `scenes/components/app_tile.gd` and `assets/phone/icons/` (launcher icon); `systems/hiring.gd`, `data/hiring.json` (live candidate data); `data/palette.json` (app colour tokens); `docs/ui-vision.md` §10 (app-specific chrome); `docs/REFERENCE.md` §3.10 Hiring; `CODEMAP.md`; `tests/test_hiring.gd` and new focused presentation/control test as needed.

**Status:** ready-for-agent

- [ ] Direction C brand/icon appears in the app and its launcher; existing phone frame/status bar and `bizA1JamesJoined` unlock gate stay intact. Define the LodedInnit visual exception in `docs/ui-vision.md`; preserve the prototype's plum/copper treatment and readable text.
- [ ] Feed/People tabs stay in one position directly below the brand header and both work. People shows only enabled roles, grouped as in direction C; live status, level/cap, wage and counts replace sample values. Row tap opens that candidate's profile.
- [ ] Role offers All, Cultivators and Crafters. Ore specialism offers All plus the five canonical ores and matches candidates whose `specialities` include the chosen ore. Both filters combine; an empty result explains that nothing matches.
- [ ] Wage starts in roster order. First tap sorts visible candidates by live weekly wage highest to lowest; second tap lowest to highest; later taps alternate. Keep role groups, sorting within each visible group. Show the active direction; filter/sort view state survives a profile round trip and app refresh.
- [ ] No inert Role/Wage/ore or `⋯` affordances. The `⋯` menu is omitted. Headless checks and focused tests cover candidate projection, filters, wage order and navigation; human check on-device at narrow phone width.
- [ ] Update `CODEMAP.md` for the directory controls and any new/repurposed files. Flag any new UI prose `PROSE-REVIEW:`.

## Comments

- Opportunity for later: collapsible role groups if the roster grows; not needed for the current eight-person list.

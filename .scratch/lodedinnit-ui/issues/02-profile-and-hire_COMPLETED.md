# 02 — LodedInnit profile and hire surface

**What to build:** Present each candidate in direction C's compact profile: identity/headline, availability, weekly wage, role, level/cap, ore specialities, experience and the live room/seat context. Keep hiring one clear action in the lower hire area, with the existing blocked reasons and float top-up confirmation fully usable. Back returns to the filtered People directory.

**Blocked by:** 01 — LodedInnit People directory and controls.

**Relevant files:** `.scratch/lodedinnit/prototype-lodedinnit.html` (direction C, pane `03 · Profile`, `hybridProfile()`, `bProfile()` and `.b`/`.c` styles; sample values are presentation only); `.scratch/lodedinnit-ui/spec.md` §Profile and hire; `scenes/phone_apps/lodedinnit_app.gd` (profile, hire action, top-up prompt); `systems/hiring.gd` (`level`, `level_cap`, `weekly_wage`, `hire_block_reason`, `has_free_seat`, `top_up_needed`, `hire`); `systems/home.gd` and `systems/contacts.gd` (room seats/specialities); `data/hiring.json`, `data/home.json`; `docs/REFERENCE.md` §3.10 Hiring and §3.3 Room seats; `docs/ui-vision.md` §10; `docs/CONTENT-GUIDE.md` §4; `CODEMAP.md`; `tests/test_hiring.gd` and new focused presentation test as needed.

**Status:** ready-for-agent

- [ ] Profile follows direction C at phone width, with live name, headline/about, role, status, level/cap, weekly wage, every ore-speciality pip and relevant role-room seat availability. No hardcoded Marcia, £300 or `1 seat free` values.
- [ ] Existing `Hiring.hire` remains the sole hire action path. Open candidate with a free seat can hire; unavailable candidate, missing/full room and other blocked cases show the system's reason and cannot hire.
- [ ] First-week price and the pot/float behavior remain accurate. When funds are short, show the existing exact float top-up question and working Yes/No choices; insufficient player cash keeps Yes disabled with its reason. Successful hire updates the profile's state.
- [ ] Back returns to People without losing selected Role/ore filters or Wage order. Profile and top-up prompt remain usable on a narrow screen, including the bottom action area during scrolling.
- [ ] Headless checks and focused tests cover the live projection and hire/top-up states; human check on-device for profile layout and disabled/active actions. Update `CODEMAP.md` for the profile/hire presentation responsibility; flag new UI prose `PROSE-REVIEW:`.

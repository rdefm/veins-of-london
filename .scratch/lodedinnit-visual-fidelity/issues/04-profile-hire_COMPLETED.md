# 04 — Direction C candidate profile and hire area

**What to build:** Candidate profile reads like direction C's compact CV, with an immediately clear weekly wage and hire decision, while all live hiring states stay usable.

**Blocked by:** 01 — Shared brand, readable ink and tabs.

**Relevant files:** `.scratch/lodedinnit-visual-fidelity/spec.md`; `.scratch/lodedinnit/prototype-lodedinnit.html` (`hybridProfile`, `bProfile`, `.b .profile-title`, `.b .availability`, `.b .salary`, `.b .specgrid`, `.b .hire-dock`, `.c`); `.scratch/lodedinnit-ui/spec.md` §Profile and hire; `scenes/phone_apps/lodedinnit_app.gd` (`_build_profile`, `_profile_stat`, `_speciality_pips`, `_build_hire_area`, top-up prompt); `systems/lodedinnit_profile.gd`; `systems/hiring.gd`; `assets/phone/icons/lodedinnit.png`; `data/palette.json`; `docs/REFERENCE.md` §3.10 Hiring and §3.3 Room seats; `docs/ui-vision.md` §10; `CODEMAP.md`; profile/hiring presentation tests.

**Status:** ready-for-agent

- [ ] Replace generic brand bar + plain `‹ People` button on profile with the prototype's compact profile nav: light-plum back text left and small LodedInnit logo right. Back returns to People with Role/Ore/Wage view state intact.
- [ ] Identity block: ~56 px subdued plum rounded-square avatar, large (~26 px) near-white bold name, smaller muted headline. Availability appears in a bordered plum badge, uppercase with status text appropriate to open, employed or ours.
- [ ] Weekly wage is a prominent standalone band with thin grey rules: small muted `WEEKLY WAGE / FIRST WEEK PREPAID` context and large copper `£…` plus subdued `/ week`. Use live wage; do not tint unrelated facts copper.
- [ ] Replace generic stacked stat rows with a compact two-column dark fact grid: role, level/cap, ore specialities and room/seat context. Use small uppercase muted labels, near-white values, and readable labelled pips for **every** live speciality. Include live experience; section labels/body follow the prototype's compact CV hierarchy. No hardcoded candidate facts.
- [ ] Pinned lower area uses dark surface, top hairline, visible role-room/seat line and one clear plum Hire/Poach CTA with first-week cost. Show blocked reason without making a disabled action look active. Float top-up question, Yes/No and insufficient-cash reason remain usable at narrow width.
- [ ] Headless Godot 4.7 checks cover open, employed, ours, blocked and top-up states, plus back-navigation state. On-device: compare profile hierarchy, vertical fit, scroll, badge, wage band, grid and pinned action with direction C.

## Comments

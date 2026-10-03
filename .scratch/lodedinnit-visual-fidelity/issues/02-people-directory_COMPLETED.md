# 02 — Compact People directory and controls

**What to build:** People reads like direction C's dense recruitment directory: a branded intro, compact functional filters, live count, role bands and scannable candidate rows. More candidates fit in the first viewport without sacrificing touch use.

**Blocked by:** 01 — Shared brand, readable ink and tabs.

**Relevant files:** `.scratch/lodedinnit-visual-fidelity/current-people.png`; `.scratch/lodedinnit-visual-fidelity/spec.md`; `.scratch/lodedinnit/prototype-lodedinnit.html` (`hybridPeople`, `bPeople`, `.b .titleblock`, `.b .list-tools`, `.b .group`, `.b .row`, `.c`); `.scratch/lodedinnit-ui/spec.md` §People; `scenes/phone_apps/lodedinnit_app.gd` (`_build_people`, `_build_controls`, `_group_header`, `_person_row`, `_avatar`); `systems/lodedinnit_directory.gd`; `scenes/components/touch_scroll_container.gd`; `data/palette.json`; `docs/REFERENCE.md` §3.10 Hiring; `docs/ui-vision.md` §10; `CODEMAP.md`; People presentation/control tests.

**Status:** ready-for-agent

- [ ] Add direction C's hierarchy: plum-charcoal intro below the tabs with a small People/count kicker, large white recruitment heading and short muted subtitle; then compact list tools. Keep tabs directly below the brand bar as approved, even though the static B mockup places its intro first. Use live count and approved copy, not hardcoded “08”.
- [ ] Replace large amber Role/Ore dropdowns and second-row amber Wage button with a compact, neutral/plum toolbar. All three controls remain clear and touchable at ~390 px; Wage shows roster/high-to-low/low-to-high state. No horizontal clipping or awkward single-control wrap. Preserve all existing filter/sort behavior and filtered counts.
- [ ] Present count like the mockup: bright number, muted availability context. Compact full-width charcoal role bands, thin top/bottom grey rules, small tracked uppercase role/count left and muted `Level / cap · £/wk` right. Groups reflect live enabled roles and filtered members.
- [ ] Candidate rows use 31 px subdued grey/plum circular initials, not the screenshot's bright outlined 36 px badges. Name ~13 px bold near-white; headline ~10–11 px muted and close to name; small uppercase light-plum availability with dot. Copper weekly wage ~12 px and muted level/cap right-aligned; add a light-plum trailing chevron. Use subtle row hairlines, ~16 px side inset, compact vertical padding and no card border per row.
- [ ] All text remains legible for long names/headlines, employed/ours status, and both role groups. At the reference viewport, density resembles direction C rather than the screenshot's two-and-a-half oversized rows. Hide only this app's visible scrollbar; keep touch scrolling.
- [ ] Row tap opens the correct live profile. Headless Godot 4.7 checks cover filters, Wage order, counts and row navigation. On-device: compare first-screen spacing/density and scroll through all eight sample-roster positions and filtered/empty states.

## Comments

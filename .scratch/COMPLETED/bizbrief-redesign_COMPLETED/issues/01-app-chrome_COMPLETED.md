# 01 — BizBrief app chrome

**What to build:** Opening BizBrief shows the selected design's own brand header, navy surface, signal-red accents, serif headings/figures, and underline tabs inside the existing phone device. Brief and Manage remain available; Staff and Stats retain their current unlock gates. This establishes reusable BizBrief styling for the later views without changing any game action.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/bizbrief-redesign/spec.md`; `.scratch/bizbrief-redesign/selected-direction.html`; `scenes/phone_apps/bizbrief_app.gd`; `scenes/phone_apps/phone_app.gd`; `scenes/screens/phone.gd`; `scenes/components/phone_device_shell.gd`; `assets/phone/icons/bizbrief.png`; `data/palette.json`; `docs/ui-vision.md` §§6–7, 10; `docs/REFERENCE.md` §2.2 Screens, §3.10 Contacts, rooms, jobs; `tests/test_phone_bizbrief.gd`; `CODEMAP.md` if ownership/files change.

- [ ] Header uses the existing BizBrief icon, live day/block, and approved brand treatment; device frame/status bar and phone-back route still work.
- [ ] Tab selection uses the approved underline style, remains readable on a narrow phone, and respects Staff/Stats gates and existing view state.
- [ ] BizBrief-specific surfaces, type and action styling do not recolour other Phone apps or global UI helpers. Fonts needed on-device are bundled or have a deliberate fallback.
- [ ] `docs/ui-vision.md` permits distinct Phone-app aesthetics and records the BizBrief direction; no mechanics, data schema, or state ownership changes.
- [ ] Focused headless checks cover opening, tab gates and navigation; all tests pass. Report on-device checks for header, tab fit and contrast.

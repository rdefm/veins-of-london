# 01 — Estate agent listings and brand chrome

**What to build:** Harrow's opens as a distinct estate agent app inside the existing phone frame. Its listing feed uses the approved mockup's white surfaces, deep green and restrained gold brand chrome, editorial headings, property photos, and clear price/fact hierarchy. All seven homes remain in canonical tier order. The current home still shows its live tenure, costs, raid risk, rooms, arrears/countdown, eligible buy-out, and plan; other homes still open particulars. This is a visual redesign, not a change to property mechanics.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

**Relevant files:** `.scratch/harrows-redesign/spec.md`; `.scratch/harrows-redesign/harrows-mockup.html`; `scenes/phone_apps/property_app.gd`; `scenes/screens/phone.gd`; `assets/phone/icons/property.png`; `data/home.json`; `tests/test_phone_property.gd`; `docs/ui-vision.md` §§6–7, 10; `docs/REFERENCE.md` tier data before §2.2, §2.2 Screens, §3.3 Home; `CODEMAP.md`.

- [ ] Listings visually follow the approved feed mockup within the existing phone frame, using Harrow's icon-derived green and gold only inside this app; other phone apps retain their styling.
- [ ] Every tier appears once in canonical order with its existing photo or fallback, name, place/copy, relevant live rent/buy and risk/room information; the current home is clearly marked.
- [ ] Current-home arrears/countdown, rented/owned terms, eligible buy-out, and existing plan remain accessible; listing taps and phone-back navigation still work.
- [ ] `docs/ui-vision.md` records the approved Harrow's exception to shared dark phone-app chrome, red actions, gold-only currency usage, and shared UI typography without changing the rules for other apps.
- [ ] Headless syntax check and all tests pass; property screen tests cover the preserved listing/current-home behaviour. Report concise on-device checks for feed legibility and scrolling.

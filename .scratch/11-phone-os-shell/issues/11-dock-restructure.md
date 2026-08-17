# 11 — Dock restructure

**What to build:** Collapse the nav bar into a 3-slot dock (Phone · Map · HQ) and remove the Bag and You tabs — safe to do now because Profile, Save/Load, and the promoted bag drawer already hold everything those tabs carried.

**Blocked by:** 07 (phone home grid), 08 (Profile app), 09 (Save/Load app), 05 (bag drawer promotion)

**Status:** ready-for-agent

- [ ] Nav bar shows exactly 3 slots: Phone, Map, HQ
- [ ] Phone slot acts as a home button: pressing it from anywhere returns to the app grid
- [ ] Pressing the Phone slot while already on the grid does nothing (no re-navigation, no flicker)
- [ ] Bag and You tabs no longer appear anywhere in the nav bar
- [ ] Map's lock (pending the Archie gate) renders using the same greyed-plus-padlock treatment as any other locked app, in the dock, replacing today's tab-label-overwrite hack
- [ ] The hint text that used to overwrite the Map tab label now surfaces as a tooltip/toast instead
- [ ] Tests cover: dock slot count and identity, Phone-as-home behavior including the no-op-on-grid case, Map's locked-state rendering

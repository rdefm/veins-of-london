# 06 — Cultivating/seeding a vein shows a blank, unresponsive white modal

**What to build:** Diagnose and fix: attempting to cultivate an existing vein, or seed a new one, currently opens a result modal that renders as an empty white overlay with no text and no working buttons — the player is stuck and can't dismiss it. After the fix, both actions must show their proper success/failure result (as already coded for the seed/cultivate result modal) and be dismissable normally.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Reproduce on a fresh save: seed a new vein — result modal shows real text (success or failure message) and a working close button.
- [ ] Reproduce on a fresh save: cultivate an existing vein — same.
- [ ] Modal is dismissable and returns control to the map/veins screen normally afterward.
- [ ] Root cause noted in the commit/PR description (this is reported as reproducing reliably, not intermittently, so it should be traceable to a specific code path rather than papered over).

# 03 — Status bar restyle

**What to build:** Restyle the existing top status bar so it reads as subdued system chrome rather than a game HUD, with zero behavior change.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Bar is visually thinner, denser, more subdued than today
- [ ] Still shows exactly the same data as today: cash, day/time-block, bag button — no new fields, no fake clock/carrier/battery
- [ ] Visibility rules unchanged: still hidden on `title`/`intro`/`map`
- [ ] Map screen's own local top bar (with its bag button) is untouched
- [ ] No fake status-bar seam is implied or built — the build runs fullscreen, so there's no real OS status bar to align against; this is styling only, not a literal-device-chrome claim
- [ ] Existing tests referencing the status bar still pass; no new behavior to test beyond visual regression (manual QA)

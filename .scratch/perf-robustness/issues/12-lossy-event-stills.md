# 12 — Lossy event stills and large backdrops

**Parent:** `.scratch/perf-robustness/spec.md`

**What to build:** Event stills and large HQ backdrops import as lossy WebP (~0.85); icons and sprites stay lossless. Expect a several-times drop on ~92 MB of event art.

**Blocked by:** None — can start immediately

**Relevant files:** `assets/events/**/*.import`, `assets/hq/*.import`, `docs/ui-vision.md` (art families); review §3.2

**Status:** ready-for-agent

- [ ] Only `assets/events/**` and large HQ backdrops change to `compress/mode=1`
- [ ] Project re-imports cleanly headless
- [ ] Human check on device: no visible banding/artifacts on a sample of stills (ticket lists 5 to look at)

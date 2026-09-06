# 01 — Manifest + placeholder renderer + debug region overlay

**What to build:** `data/hq_visuals.json`, following the `data/combat_visuals.json`
precedent exactly — every plate and sprite has an `image` path that may be
`""`, plus hand-authored hit regions. A renderer that draws a labelled
placeholder box in the correct region for any empty `image` path, so the
whole tab is navigable and tappable with zero art produced. A debug toggle
that draws every hit region and sprite rect over the art with its id, since
the agent cannot see the UI and the human is visual QA.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `data/hq_visuals.json` schema mirrors `combat_visuals.json` (image path + fallback, hit regions)
- [ ] Loader reads the manifest into `GameData` at boot, same pattern as `GameData.COMBAT_VISUALS`
- [ ] Empty `image` path renders a labelled placeholder box, not a blank space or error
- [ ] Debug overlay toggle draws every hit region + sprite rect + id, can be enabled/disabled at runtime
- [ ] No hardcoded room/zone roster in the reader — iterating the manifest's keys is enough to add a new plate later

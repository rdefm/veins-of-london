# 10 — Harvest chooser preview update

**What to build:** Tapping Harvest on the compact bubble (ticket 09) opens a light/hard chooser showing the ore yield and resulting condition for each option, computed with ticket 04's level-scaled yield and updated harvest depths (light=9/hard=24), before the player selects. Normal action availability and domain validation still apply.

**Blocked by:** 04, 09.

**Relevant files:**
- Harvest chooser UI (owned by the bubble/action flow from ticket 09 — locate the existing prune/harvest confirmation surface during implementation; none is currently named in CODEMAP, so this ticket also adds it there once built)
- `systems/cultivating.gd` (`prune()` — preview must call the same yield/condition math as the real action)

**Status:** ready-for-agent

- [ ] Chooser shows both light and hard options with actual ore yield and resulting condition, computed via the real yield/depth formulas (not placeholders)
- [ ] Preview does not assume every harvest exits the development zone — it shows the true post-harvest condition
- [ ] Domain validation (ore type match, time budget, etc.) still gates availability as today
- [ ] CODEMAP.md updated with the chooser's owning file once implemented

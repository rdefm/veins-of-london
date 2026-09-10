# 07 — Ore-store readout → handwritten inventory slip

**What to build:** `modal_layer.gd`'s `_build_hq_ore_readout()` re-skins
as a handwritten inventory slip — running totals per ore type styled as
if updated by hand every time stock changes, per `docs/ui-vision.md` §5.
The existing raid-warning line renders on the **same slip** (e.g. a
stamped/red-ink annotation using `ui_action_red`) rather than as a
separate card/section.

**Blocked by:** 01

**Status:** ready-for-agent

- [ ] Ore-store readout renders as a single inventory-slip object (per-ore-type totals in a handwritten-style treatment)
- [ ] Raid-warning line renders on the same slip, not a separate card/section
- [ ] Existing content (which ore types show, the raid-warning condition) unchanged — this is a rendering swap only
- [ ] `tests/test_modal_layer.gd` updated for the new styling
- [ ] Flag `ART-REVIEW` in the task report if the "handwritten" treatment needs a produced texture asset rather than being achievable in pure vector/font styling

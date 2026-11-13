# 04 — Cultivate: ring animation is the sole focus

**What to build:** After tapping Cultivate, the fullness ring/'bar' increasing is the only focus on screen for 1.5–2 seconds (other UI dimmed/blocked), then the normal result appears.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/map_canvas.gd` (`_on_vein_cultivated` ~L941, `_ring_overrides`), `scenes/screens/map.gd` (~L209), `scenes/components/vein_detail_panel.gd`, `data/` timing constants if any.

**Status:** ready-for-agent

- [ ] Ring tween runs 1.5–2s (duration in data), nothing else competing for attention
- [ ] Input blocked or panel dimmed during the tween; result/level-up shown after
- [ ] Works for level-up and no-level-up cultivates
- [ ] State mutation still happens via system call, not screen

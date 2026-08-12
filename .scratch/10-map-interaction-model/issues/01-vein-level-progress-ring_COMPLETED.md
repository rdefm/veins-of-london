# 01 — Vein level progress ring

**What to build:** The vein level badge on the Network map (`MapCanvas._draw_level_badge`) currently shows a plain circle with the level number and a thin full-circle outline. Replace the outline with a thick progress arc showing how close the vein is to its next level (`vein.devBar / vein_levels.json[level].devBarMax`). At a vein's max effective level, the ring shows full (100%), not hidden. Once a vein is at max effective level, its Cultivate action becomes disabled with a reason label instead of doing nothing or staying silently available.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Level badge renders a thick arc around its edge, filled proportionally to `devBar / devBarMax` for the vein's current level.
- [ ] A vein at its effective max level (cap 5, or 6 with the "maxLevel" hospitability bonus) shows a full ring, not an empty/hidden one.
- [ ] Wherever the Cultivate action is currently triggered (today's site sheet, and later the station bubble in ticket 04), the button is disabled with a visible reason label when the target vein is at its effective max level — never hidden.
- [ ] Ring rendering degrades sensibly at both min and max map zoom (readable, not just a solid blob or invisible sliver).
- [ ] Test coverage for the devBar/devBarMax → fill-fraction calculation, including the max-level-is-full edge case.

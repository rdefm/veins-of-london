# 06 — Dial level, XP and next-level gains on the overview

**What to build:** The player can't see their Dial level, current XP, how to level it, or what levelling gives. Add a pure system projection of a Dial's progression (level, XP, next threshold or max, how XP is earned, and the next level's gains: Complication capacity, Lens slots, cast magnitude multiplier, Black Hole freeze bonus) and show it on the Dial overview: level, XP bar X/Y, and a "Next level" panel. At max level show "Max level".

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/dial.gd` (`capacity_max`, `lens_slots`, `cast_level_multiplier`, `cast_black_hole_freeze_bonus`, cast XP award ~l.671), `systems/progression.gd`, `systems/soul.gd` (`dial_xp_mult`), `data/dial.json` (`xpLevels`, `capacityByLevel`, `lensSlotsByLevel`), `scenes/components/dial_menu.gd`, `tests/test_dial.gd`. REFERENCE.md §3.5, §1.4 Lenses.

**Status:** ready-for-agent

- [ ] System func returns level/xp/next threshold/next-level deltas from data only (no hard-coded numbers)
- [ ] Tests cover L1, mid level, max level
- [ ] Overview shows level, XP bar, how XP is earned, next-level gains
- [ ] Works per owner (player and contact Dials)
- [ ] New UI strings flagged PROSE-REVIEW

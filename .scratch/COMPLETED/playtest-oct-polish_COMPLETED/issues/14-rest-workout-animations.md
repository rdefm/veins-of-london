# 14 — Rest and workout animations

**What to build:** Taking a rest or training at the gym plays a short animation, in the same style as the time-block animations:
- Rest: the health bar fills up.
- Workout: the combat XP bar fills up.

If the action moves time on, the existing time-block animation plays after it. Screens only read state before and after the action to drive the animation; no state mutation in the screen.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/time_system.gd` (rest), `scenes/modals/hq_gym_modal.gd` (Train), `systems/combat.gd` (`skill_summary`), `scenes/components/top_bar.gd`. Locate the existing time-block animation component first (not found in CODEMAP); reuse it.

**Status:** ready-for-agent

- [ ] Rest plays the animation with the HP bar rising from the before to the after value
- [ ] Train plays the animation with the XP bar rising (level-up handled)
- [ ] Time-block animation follows when the block advances, not otherwise

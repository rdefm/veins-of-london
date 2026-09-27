# 139 — HQ training shows combat level and what it gives

**What to build:** The HQ gym/training modal shows the player's current combat level, an XP progress bar to the next level (current/needed), and what the level gives now — HP bonus, attack bonus, speed — plus what the next level adds (e.g. "Next: +5 HP, +1 ATK"). At max level it says so and hides the "next" line. The screen reads this through a system helper; numbers come from the existing level tables.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/modals/hq_gym_modal.gd`, `systems/combat.gd` (`train`, `award_xp`, level-table usage ~L302/L652/L876), `systems/progression.gd`, `autoload/GameData.gd` (`COMBAT_XP_LEVELS`, `COMBAT_HP_BONUS_BY_LEVEL`, `COMBAT_ATTACK_BONUS_BY_LEVEL`, `COMBAT_SPEED_BY_LEVEL`); REFERENCE.md §3.7a "Combat Skill".

**Status:** ready-for-agent

- [ ] The read helper returns level, xp, xp needed for next, current bonuses and next-level gains; tested incl. max level
- [ ] Modal shows the level, bar, current bonuses and next-level gain
- [ ] Bar updates right after Train
- [ ] Human on-device: open the gym, train once, see the bar move; check the wording

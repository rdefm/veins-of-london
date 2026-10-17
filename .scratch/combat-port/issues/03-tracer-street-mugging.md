# 03 — Tracer: street mugging on the new engine, end to end

**What to build:** A street mugging launched from the prep sheet plays under the Open/Guarded rules on the live combat screen. The player fights with real HP (hpMax from the Combat Skill curves), all six moves, fog off the player's Combat Skill, and the mugger template's archetype and level from §3.7b. The real two-slot loadout rows are shown; item effects arrive in 06, so this ticket may block them with a reason.

The prototype screen becomes the live combat screen, wired to `Combat`: strip carousel with intents and `?`, guard overlay, block-reason `?`, beat playback, pacing toggle, top bar, Bag drawer. Outcomes go through the existing exit/outcome dispatch, so a mugging win/loss/flee has its existing consequences. XP is the lump: win 30, loss 3, Leg it 0. A mid-fight save restores the new state shape. The Gym card shows actions per round and crit chance alongside HP/ATK/SPD.

Every other context still runs on the old engine (transitional routing, removed in 13). Rewind is not offered yet (08).

**Blocked by:** 01, 02

**Relevant files:** `systems/combat.gd` (`start_street_mugging`, `_start_combat`, `exit_combat`, `award_xp`, `skill_summary`); `systems/combat_prototype.gd`; `systems/combat_prep.gd`; `scenes/screens/combat.gd`; `scenes/screens/combat_prototype.gd`; `scenes/components/combat_stage.gd`; `scenes/components/turn_order_strip.gd`; `scenes/components/combat_command_dock.gd`; `scenes/components/combat_director.gd`; `scenes/modals/combat_block_reason_modal.gd`; `scenes/modals/hq_gym_modal.gd`; `autoload/GameState.gd`; `autoload/SaveManager.gd`; `data/enemies.json`; `data/combat_prototype.json`; `tests/test_combat.gd`; `tests/test_combat_screen.gd`; `CODEMAP.md`; REFERENCE §3.7b, §2 (combat state paths)

**Status:** ready-for-agent

- [ ] A street mugging from prep runs on the new rules; seeded tests cover guard/strike/chip, feint, stun, lure, Leg it success and fail
- [ ] Real HP is spent; a win/loss/flee runs the existing mugging consequences
- [ ] XP: win +30, loss +3, Leg it +0
- [ ] Save mid-fight, load, and the fight resumes at the same pause
- [ ] Gym card shows actions/round and crit
- [ ] Other contexts still play on the old engine; the full suite passes

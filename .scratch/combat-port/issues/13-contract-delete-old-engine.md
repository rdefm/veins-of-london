# 13 — Contract: delete the old engine and the prototype

**What to build:** No fight uses the old code, so remove all of it:
- the speed-queue/Attack engine bodies and the `turnCursor`-era helpers nothing calls any more;
- the transitional routing;
- the sandboxed prototype system, screen, data and tests;
- the `combatPrototype` state key and Snapshots stack, plus its GameData validation and SaveManager handling;
- the Debug prototype card;
- the old itemless sim and the prototype sim.

Whatever data the live engine still reads from the prototype table moves to its permanent home. Combat-related CODEMAP rows describe current state only. Token-lint allowlist entries for deleted files are removed.

**Blocked by:** 05, 07, 08, 09, 10, 11, 12

**Relevant files:** `systems/combat.gd`; `systems/combat_prototype.gd`; `scenes/screens/combat_prototype.gd`; `data/combat_prototype.json`; `tests/test_combat_prototype.gd`; `tests/test_combat_prototype_screen.gd`; `scripts/sim_combat_prototype.gd`; `scripts/sim_combat_prototype_impl.gd`; `autoload/GameData.gd`; `autoload/GameState.gd`; `autoload/SaveManager.gd`; `autoload/Snapshots.gd`; `scenes/phone_apps/debug_app.gd`; `scenes/components/top_bar.gd`; `CODEMAP.md`; `scripts/lint_tokens_allowlist.txt`; REFERENCE §3.7/§3.7a/§3.9 (remove superseded text)

**Status:** ready-for-agent

- [ ] No reference to the old engine or the prototype remains (grep clean)
- [ ] REFERENCE superseded combat text removed or pointed to §3.7b
- [ ] Full suite and `scripts/check_all.sh` clean
- [ ] CODEMAP current

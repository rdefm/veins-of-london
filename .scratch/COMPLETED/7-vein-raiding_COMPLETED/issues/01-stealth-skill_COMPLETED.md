# 01 — stealthSkill (third skill, alongside crafting/cultivating)

**What to build:** A new player skill, `stealthSkill`, gating Direction A's stealth check per the PRD ("a new dedicated skill, third alongside `craftingSkill`/`cultivatingSkill`, same progression shape"). Add `stealthSkill`/`stealthXP` fields to `state.player` (default `1`/`0`, mirroring `craftingSkill`/`craftingXP` in `autoload/GameState.gd`) and to the contacts state (`_new_contacts_state()`) and `SaveManager.gd`'s save/load field lists, same as the existing two skills. Display it on the You screen (`scenes/screens/you.gd`) alongside the existing "Crafting: Lv%d (%d XP)" / "Cultivating: Lv%d (%d XP)" lines. No XP-award call sites yet — those land with ticket 02, which is the first system that actually grants stealth XP.

**Blocked by:** None — can start immediately

**Status:** ready-for-agent

- [ ] `stealthSkill` (default `1`) and `stealthXP` (default `0`) added to `state.player` in `autoload/GameState.gd`, same shape as `craftingSkill`/`craftingXP`
- [ ] Same two fields added to the contacts state shape (`_new_contacts_state()`), matching how `craftingSkill`/`cultivatingSkill` already exist per-contact
- [ ] `SaveManager.gd`'s player and contact save/load field lists include the two new keys (the existing `for key in [...]` lists at lines ~181 and ~223)
- [ ] You screen (`scenes/screens/you.gd`) displays "Stealth: Lv%d (%d XP)" alongside the existing Crafting/Cultivating lines
- [ ] Tests cover: new-game state has `stealthSkill == 1` and `stealthXP == 0`; save/load round-trips both fields for player and for a contact
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes

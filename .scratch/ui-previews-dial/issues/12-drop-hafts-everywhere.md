# 12 — Drop hafts everywhere else

**What to build:** Remove the haft concept from the game. The Dial loadout card reads "Level N Dial" with no haft name. The six-haft list and its load-time validation are removed from the Dial data. James's granted Dial no longer names a haft. Setting and naming a haft are no longer possible. Contact Dials share the player's umbrella look. Old saves that still store a haft on a Dial load and play normally; the stale field is ignored or dropped.

**Blocked by:** 11 — Seed a Dial without a haft

**Relevant files:**
- `systems/dial.gd` (`set_haft`, `haft_name`, `new_dial`, contact grant from `grantDial`)
- `autoload/GameData.gd` (`DIAL_HAFTS`, manifest entry, haft validation near the dial validator)
- `autoload/GameState.gd` (Dial shape comment around the dial state)
- `data/dial.json` (`hafts`), `data/constants.json` (james `grantDial.haft`)
- `scenes/components/dial_loadout_menu.gd` (level/haft label line)
- `tests/support/fixtures.gd` (`haftId` in Dial fixtures), `tests/test_savemanager.gd`, `tests/fixtures/gamedata_pre_manifest_snapshot.gdvar`
- REFERENCE §1.4 `data/dial.json`, §3.5, the contacts constants line (james `grantDial`)
- `docs/device-plan-spec.md`, `docs/hq-diorama-vision.md` (stale haft mentions)
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] No haft data, validation, state field, setter or name helper remains
- [ ] Loadout card label shows the level only
- [ ] James's granted Dial is built without a haft
- [ ] A save containing a haft on a Dial still loads (test)
- [ ] REFERENCE and CODEMAP updated; tests pass

# 10 — New Dial menu in Profile and combat prep

**What to build:** Replace the Dial views in the phone Profile app (player and contacts' Dials) and on the combat Preparation sheet with the new Dial menu component from 07/08, so all three places share it. Retire DialLoadoutMenu once nothing uses it. The in-fight Dial-casting widget is out of scope.

**Blocked by:** 08 — New Dial menu: Movement and Complication sections, Craft

**Relevant files:**
- `scenes/phone_apps/profile_app.gd`
- `scenes/screens/combat_prep.gd`
- `scenes/components/dial_loadout_menu.gd` (delete when unused)
- `systems/dial.gd` (`dial_of(owner_id)` for contacts)
- tests: `tests/test_phone_profile.gd`, combat prep tests
- `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Profile (player + contact Dials) uses the new menu
- [ ] Combat prep uses the new menu; prep flow (loadoutEdit round-trip) unaffected
- [ ] DialLoadoutMenu removed if unused; CODEMAP updated
- [ ] Tests pass for Profile and combat prep

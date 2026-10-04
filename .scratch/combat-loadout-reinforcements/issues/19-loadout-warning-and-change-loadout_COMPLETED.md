# 19 — Empty-slot warning and Change loadout round-trip

**What to build:** When a participating player or recruit has an empty slot while eligible unequipped stock exists, preparation shows a warning naming that character and offering Change loadout. It opens Profile focused on the current participants (personal items and Dials, including winding — not guard kits), then returns to the same pending encounter with the updated view and no costs committed.

**Blocked by:** 10, 17

**Relevant files:** preparation screen (from 17), `scenes/phone_apps/profile_app.gd`, `scenes/screens/hq_dial.gd` (shared Dial menu), screen routing in `autoload/GameState.gd`, `tests/test_phone_profile.gd`, `tests/test_combat.gd`.

**Status:** ready-for-agent

- [ ] Warning appears only when a participant has an empty slot and eligible stock exists, and names them
- [ ] Change loadout opens Profile focused on participants only
- [ ] Returning lands on the same pending encounter showing the updated loadout; nothing committed
- [ ] Guard kits not editable from this route
- [ ] PROSE-REVIEW flag on warning text; on-device QA block

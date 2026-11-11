# 10 — Vein loss, room loss and Light-fingered

**What to build:** Guards never transfer with a vein. A player vein taken by force sends its posted guards to Reserve, unhurt; selling or buying a vein moves no guards (a sold vein's guards go to Reserve); a vein the player takes arrives with no guards.

Losing the Security Office (arrears downgrade below townhouse, no free slot on a tier move, or replaced): guards stay employed and keep being paid, posts and fights keep running, management is locked (`can_manage()` false), vein posts freeze, HQ guards drop to Reserve below townhouse, Short Pay still works, and one notification says guards hold their posts but can't take new orders. Re-buying restores management; the intro never replays.

**Light-fingered:** each Monday, 10% chance that 1 kit unit at that guard's post goes missing.

**Blocked by:** 06 — XP, levels, training and the Muscle daily tick.

**Relevant files:**
- `systems/muscle.gd` (`on_vein_lost`, `on_room_lost`, `daily_tick` Monday roll)
- `systems/home.gd` (`change_tier`, `room_carryover`, arrears downgrade), `systems/rooms.gd`
- `systems/vein_trade.gd`, `systems/raiding.gd` / `systems/faction_ai.gd` / `systems/warmonger.gd` (vein taken by force), `systems/guard_kit.gd` (`remove_units`)
- `systems/notify.gd`
- Tests: `tests/test_muscle.gd`, `tests/test_home.gd`, `tests/test_vein_trade.gd`, `tests/test_guard_kit.gd`

**Status:** ready-for-agent

- [ ] Vein lost by force → its guards in Reserve, uninjured; sell/buy moves none; a captured vein has no guards
- [ ] Room loss: management refused, wages and posts continue, HQ guards to Reserve below townhouse, one notification
- [ ] Re-buy restores management with no intro replay
- [ ] Light-fingered: seeded Monday roll removes 1 unit from that post's kit at 10%
- [ ] PROSE-REVIEW flagged: room-loss notification

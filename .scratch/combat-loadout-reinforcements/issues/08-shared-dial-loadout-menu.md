# 08 — Shared Dial loadout menu (Profile + HQ)

**What to build:** One Dial loadout menu, opened from both Profile and HQ, edits the player's Dial: seat/unseat crafted Movements and load/unload crafted Complications (moving real units to/from shared inventory), and wind the Dial with its existing cost and no-time-block rule. Both entry points show identical state because they are the same menu. The menu takes an owner so later tickets can open it for recruits; a character without a Dial shows no Dial loadout.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/screens/hq_dial.gd`, `scenes/phone_apps/profile_app.gd`, `scenes/modals/movement_swap_modal.gd`, `scenes/modals/dial_load_complication_modal.gd`, `systems/dial.gd`, `tests/test_hq_dial.gd`, `tests/test_dial.gd`, `tests/test_phone_profile.gd`, `CODEMAP.md`. Update REFERENCE §1.4, §3.5 with the change.

**Status:** ready-for-agent

- [ ] Profile and HQ open the same menu component
- [ ] Seat/unseat and load/unload conserve units
- [ ] Winding works from both entry points with existing cost and no time block
- [ ] Menu accepts an owner id; a no-Dial owner renders no Dial section
- [ ] On-device QA block in report

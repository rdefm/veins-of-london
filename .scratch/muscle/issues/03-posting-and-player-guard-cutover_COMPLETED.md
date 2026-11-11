# 03 — Posting and player guard-count cutover

**What to build:** Guards can be posted. Posts are HQ (`home`) and each player vein, capped at 4 each; Reserve is uncapped. Moves are instant, free, no cooldown, any time block, and require `can_manage()`. One system function backs every entry point. The Security screen gains the **Posts** tab (place-centric groups HQ / each vein / Reserve with count, weekly cost and kit status; "+ Assign" picks from Reserve, showing "No one in reserve — Hire ›" when empty; "→ Reserve" on a posted guard) and the guard detail sheet gains the "Post ▾" picker (HQ, every vein, Reserve).

Cutover — Muscle becomes the only source of player guard bodies: the vein guard count, HQ guard count and guard-kit capacity derive from available guards posted at that place. Removed: player `extraGuards`, `home.guardCount`, the vein `guarded` security tier (player tiers top out at warded), the vein-panel "+1 guard" purchase, and the HQ "Hired Guard" security item and its compound gate. Debug start seeds muscle records instead of counts. An all-L1 roster gives exactly today's resist, repel, kit capacity and wages. Wide refactor: keep the public signatures of the wrapped functions so call sites keep working.

**Blocked by:** 02 — Security Office room, hire board, Guards tab.

**Relevant files:**
- `systems/muscle.gd` (`post`, `cap`, `guards_at`, `reserve`, `is_available`)
- `systems/cultivating.gd` (`vein_guard_count`, `drop_vein_guard`, security tiers), `systems/home.gd` (`get_guard_count`, `guard_repel_chance`), `systems/guard_kit.gd` (`capacity`, `hq_capacity`, `target_guard_count`), `systems/raiding.gd` (`guard_repel_chance`, `guards_repel`), `systems/guard_upkeep.gd` (`player_guards_by_place`)
- `data/vein_security.json` (drop `guarded`), `data/home.json` (drop `guard` security item)
- `systems/debug_start.gd`, `systems/combat_prep.gd`, `systems/network_handler.gd`, `systems/events.gd` (grep guard consumers)
- `scenes/components/vein_detail_panel.gd` (remove "+1 guard"), Security screen
- Tests: `tests/test_home.gd`, `tests/test_guard_kit.gd`, `tests/test_hq_guard_kit.gd`, `tests/test_cultivating.gd`, `tests/test_raiding.gd`, `tests/test_hq_door.gd`, `tests/test_muscle.gd`
- REFERENCE.md §1.6 (guards, kit); CONTEXT.md **Post**, **Reserve** (note "Guarded" is the combat guard-state term, unrelated); CODEMAP.md

**Status:** ready-for-agent

- [ ] Posting refuses without the room, past cap 4, or for an unavailable guard; Reserve takes any number
- [ ] Posts tab "+ Assign", "→ Reserve" and the detail "Post ▾" all call the same system function
- [ ] Vein/HQ guard counts and kit capacity equal the number of available guards posted there
- [ ] No reference to player `extraGuards`, `home.guardCount`, the vein `guarded` tier or the Hired Guard item remains in code or data
- [ ] All-L1 parity test: resist, repel chance, kit capacity and Monday bill equal pre-change values for the same body counts
- [ ] Full suite + `check_all.sh` clean
- [ ] On-device check listed: Posts tab groups, Assign/Reserve, Post picker, empty-Reserve hire link

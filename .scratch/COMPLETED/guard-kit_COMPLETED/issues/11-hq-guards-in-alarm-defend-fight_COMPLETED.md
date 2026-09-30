# 11 — HQ guards in the alarm-defend fight

**What to build:** In the Alarm System defend fight at HQ, HQ guards join as "Hired Guard" allies (after any contacts, up to `SQUAD_MAX`). They use `home.guardKit` under every guard-turn rule from tickets 07–08. `exit_combat` takes `used` off `home.guardKit` on a win, loss or flee. The scripted tutorial `home_raid` fight is unchanged.

**Blocked by:** 08 — Guard Rewind + Enhancement Powder; 09 — HQ guard kit state.

**Relevant files:** `systems/combat.gd` (`start_home_alarm_defend_combat` ~385, `HOME_CONTEXTS` ~33, `_start_combat`, `exit_combat` home-alarm branch ~2007), `systems/home.gd` (`trigger_defend` ~152), `tests/test_combat.gd`. Spec §HQ guard kit. REFERENCE.md §3.7.

**Status:** ready-for-agent

- [ ] The alarm-defend fight seeds guard allies from the HQ guard count and the kit pool from the active `home.guardKit`.
- [ ] Used units come off `home.guardKit` after the fight, and a KO'd HQ guard is still counted afterwards.
- [ ] The tutorial `home_raid` fight has no guard allies. REFERENCE §3.7 is updated.

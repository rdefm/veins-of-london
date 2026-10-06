# 04 — Winning the home raid skips Archie's partner debrief

**What to build:** On a new game, after winning the home raid, the Archie debrief (where he proposes the partnership and gives the player his time vein) never plays — the game returns straight to the normal menu. Because that debrief is what sets `archiePartnerSeen`, the Map tab and the time vein stay permanently locked. Find the root cause (combat exit does request the debrief event, yet the player lands on the menu) and fix it so the debrief always plays after the home raid and unlocks progression. New games only — no save repair needed.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (`_exit_home_raid`, ~line 2913), `systems/events.gd` (`start_event`), `scenes/screens/combat.gd` (exit/route handling), `systems/home.gd`, `data/events/home_raid_debrief_win.json`, `data/events/home_raid_debrief_loss.json`, `data/objectives.json` (`tut_archie_partner`), `scenes/components/nav_bar.gd` (~line 116, Map lock), `scenes/screens/phone.gd` (~line 112), `tests/test_playthrough.gd`, `tests/test_combat.gd`

**Status:** ready-for-agent

- [ ] Root cause identified and noted
- [ ] Winning the home raid from a new game shows the win debrief; completing it sets `archiePartnerSeen` and unlocks the Map tab (test through the real combat-exit → screen route)
- [ ] Losing the home raid likewise shows the loss debrief and sets the flag
- [ ] Human checks on device: new game → home raid win → Archie debrief plays → Map tab opens and the vein is obtainable

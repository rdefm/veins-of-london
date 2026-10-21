# 02 — Scripted fights: fixed plans, forced crits, Rewind lock

**What to build:** An event can open a **scripted fight** from data, which is what the Prologue cold open needs. Enemy round plans are fixed. A named enemy's first action can land before the player's first pick (the sucker punch), with a forced crit/KO on a named ally (Archie). All moves stay open, and there's no Cancel. The fight can't be won. When the player falls below a set HP, the action bar locks to the Rewind, with a prompt line from data. After the player taps it (a T5 rewind, so back to the fight start), scripted beats play: the ally Guards the opening punch, the ally throws a Time Pearl (freeze shown), and the player's Leg it succeeds. Then the fight exits back to the event. Source: `docs/story-restructure.md` Prologue step 1, "Features to build" item 2.

**Blocked by:** 01 — Rewind tiers.

**Relevant files:** `systems/combat.gd` (open_fight, exit routing ~L1420, `round_rewind`), `systems/combat_rounds.gd` (plans, timeline, crit/KO), `systems/combat_prep.gd` (forced encounters, no Cancel), `systems/events.gd` (start-combat ops ~L820–860), `scenes/components/combat_director.gd`, `combat_stage.gd`, `combat_command_dock.gd`. REFERENCE §3.7a, §3.7b, §3.9a (event op schema).

**Status:** ready-for-agent

- [ ] A new event op starts a scripted fight from a data block: roster, allies, fixed per-round enemy plans, forced crit/KO targets, HP lock threshold, prompt line, post-Rewind script, and the event card to resume at.
- [ ] Scripted fights can't end in a player win before the lock triggers (damage/plans are tuned or forced), and there's no Cancel.
- [ ] Below the threshold, only the Rewind is selectable. The player must tap it; nothing auto-fires.
- [ ] After the Rewind, the scripted beats resolve in order with their normal beats/animations (guard, freeze, flee), and the fight exits as `fled` back to the event.
- [ ] Rewind unit spent and XP handled by normal rules. Save/load mid-fight keeps the script position.
- [ ] A test fixture event exercises the whole path headless (`tests/`). The human checks the cold-open feel on device.

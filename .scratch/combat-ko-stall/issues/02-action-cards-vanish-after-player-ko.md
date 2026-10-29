# 02 — Action cards vanish after player KO

**What to build:** Bug fix. Once the player is KO'd and an ally is still standing, the fight continues as the spec says (allies fight on unpaused). But from the round after the KO, no action cards appear at all, and the fight plays out invisibly. Diagnose why, then fix it so the ally's and the enemies' action cards keep rendering every round until the outcome, exactly as they do in a normal round. The player's own cards are absent while they're KO'd, as before.

Reported repro: likely a mugging, with Archie as the ally, and the player gets KO'd. All cards stop from the round after the KO.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/combat_rounds.gd` (`playerKoed` field ~176, round loop ~1855, KO handling ~2003-2010, `_check_outcome()` ~2606)
- `scenes/screens/combat_rounds.gd` (`playerKoed` roster ~1118, card/dock render path)
- `scenes/components/combat_command_dock.gd`
- `tests/test_combat_rounds.gd`
- REFERENCE.md §3.7b "KO and outcome", §3.7a "Player KO"

**Status:** ready-for-agent

- [ ] Root cause identified and stated in the report
- [ ] After a player KO with an ally standing, ally and enemy action cards show every subsequent round until the outcome
- [ ] Regression test reproduces the KO-then-continue path (no loops on game-state conditions; iteration cap)
- [ ] On-device check listed in the report

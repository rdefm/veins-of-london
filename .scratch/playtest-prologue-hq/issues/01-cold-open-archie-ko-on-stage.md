# 01 — Cold open: Archie on stage, KO shown

**What to build:** When the cold-open fight opens, Archie is visibly standing on stage beside the player. Nick's scripted crit then knocks him out on screen: hit, fall/KO pose, and a transcript line. Right now the player only reads coach text saying Archie is down and never sees it happen.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/cold_open.json` (Brace → `start_scripted_fight`, `forcedHits`, `coach.lessons`), `systems/combat_rounds.gd` (forced hits, scripted lock), `scenes/screens/combat_rounds.gd`, `scenes/components/combat_stage.gd`, `scenes/components/combat_director.gd`, `tests/test_cold_open.gd`; REFERENCE.md §3.7b.

**Status:** ready-for-agent

- [ ] Fight opens with Archie standing and visible on stage before any beat resolves
- [ ] Nick's forced KO on Archie plays as a beat the player watches (hit + KO keypose + transcript line)
- [ ] The "Archie's down" coach line appears after the KO beat, not in place of it
- [ ] Headless test: the KO beat sits in the played beat queue with Archie as the target and koed=true afterwards
- [ ] On-device check listed in the report

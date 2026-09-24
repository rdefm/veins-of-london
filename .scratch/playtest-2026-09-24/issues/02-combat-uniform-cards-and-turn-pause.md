# 02 — Combat: uniform turn cards + pause between combatants

**What to build:** In combat, the turn-order strip only enlarges a card while it's the player's decision turn. While a round resolves (enemy and ally turns, and the player's resolved action), every card is the same size. Add a short pause between each combatant's turn so beats read one at a time — roughly 0.5s on normal pacing, shorter on quick pacing, value in data. Rewind playback follows the same sizing/pause rules.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/turn_order_strip.gd`, `scenes/screens/combat.gd`, `scenes/components/combat_director.gd`, `systems/combat_pacing.gd`, `data/combat_visuals.json`, `docs/combat-animation-vision.md`; REFERENCE §3.7a.

**Status:** ready-for-agent

- [ ] Card grows only on the player's decision turn; uniform size during resolution
- [ ] Pause between each combatant's turn, data-driven, scaled by normal/quick pacing
- [ ] Rewind playback behaves the same
- [ ] Tests cover sizing state per phase and pause selection per pacing

# 04 — Round timeline on the strip + guard badges

**What to build:** The turn-order strip shows the Combat Prototype's current round as one interleaved timeline, so the player reads intents and plans at a glance.

- One card per timeline position, in resolution order: enemy actions show their intent (move type; plus target and damage range under Prophet's Breath sight), ally actions show their planned move/item and target, player positions show the resolved pick or the current pause (focused/expanded card).
- Each card carries a guard-state badge: the actor's guard state after that action (Open / Guarded / Exposed), taken from the system's guard preview. Resolved positions show the actual result.
- HP on the cards follows each combatant; HP ghost drains during playback, as live.
- During playback the strip advances position by position with the beats.
- Under sight, a next-round row/section shows the enemies' next-round intents.
- Removed actions (stun/freeze/KO) drop off or show as lost.

**Blocked by:** 03.

**Relevant files:** `scenes/components/turn_order_strip.gd` (`configure`, `advance_to`, `_build_card_content`, `NameplateCard`), `scenes/screens/combat_prototype.gd`, `systems/combat_prototype.gd` (`timeline`, `enemy_intents`, `guard_preview`, `has_sight`), `scenes/screens/combat.gd` (`_configure_turn_order_strip`, queue playback reference), `tests/test_combat_prototype_screen.gd`.

**Status:** ready-for-agent

- [ ] Screen test: strip entry count and order match the system timeline for a seeded 1v2 + ally fight.
- [ ] Screen test: without sight, enemy cards carry no target/damage; with sight they do, and next-round intents appear.
- [ ] Guard badge per card matches the guard preview.
- [ ] Strip advances during playback without rebuilding mid-beat.
- [ ] On-device QA list in the report.
- [ ] `PROSE-REVIEW:` on any new badge/intent strings.

# 03 — Prologue home raid: raider counters perfectly, the pearl turns it

**What to build:** Right now the prologue home raider is easy to beat without the pearl, so forcing the pearl feels arbitrary. Make the raider play perfect counters instead:
- The player picks an attack → the raider Guards.
- The player Guards → the raider Feints, then Strikes.

Normal play then visibly gets nowhere. The existing lock and notification push the player to the pearl (playtest-prologue-hq 06). Once the pearl is used, every player hit is a guaranteed crit for the rest of the fight, so the player can knock the raider out quickly. The raider's stats don't change: the difficulty comes from the AI, not a stat rebalance. Other home raids keep normal rules. Any new prompt or notification line follows `docs/writing-guide.md`; flag it PROSE-REVIEW.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/combat.gd` (`start_home_raid_combat`, `_home_raider_enemy`), `systems/combat_rounds.gd` (enemy move choice, scripted lock, crit resolution), `data/events/home_raid_intro.json`, `data/events/home_raid_debrief_win.json`, `data/events/home_raid_debrief_loss.json`, `tests/test_prologue_chain.gd`; REFERENCE.md §3.7b Open/Guarded round combat, §3.7 Combat.

**Status:** ready-for-agent

- [ ] The prologue raider picks the counter to the player's committed move (Guard vs attack; Feint then Strike vs Guard)
- [ ] The counter behaviour and post-pearl crits are flagged in data on the prologue raid, not hard-coded to an event id
- [ ] After the pearl is played, every player hit crits until the fight ends
- [ ] The existing lock and notification still steer to the pearl
- [ ] Raider stats unchanged; non-prologue home raids unchanged
- [ ] REFERENCE.md §3.7b documents the counter AI and post-pearl crit
- [ ] Headless test: a no-pearl plan can't win; pearl, then strikes, wins with crits

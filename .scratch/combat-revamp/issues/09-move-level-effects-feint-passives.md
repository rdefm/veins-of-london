# 09 — Move-level effects: Feint passives

**What to build:** Feint levels add damage and defensive passives, for every combatant. All numbers in data.
- **Damage:** a feinted target takes +0/+10/+20/+30/+40% damage (by the feinter's Feint level) while the Feint's opening holds.
- **Passives — only while the actor's last resolved action was a Feint:**
  - **Autoguard:** chance to treat one incoming hit as Guarded (chip) — 33% at L3, 50% at L4, 66% at L5.
  - **Retaliate (L5):** 33% chance to Strike the attacker back immediately, costing no action. Can trigger alongside an autoguard (guard the hit, then retaliate).
- Each passive firing gets a transcript line and a stage beat.

**Blocked by:** 07 — Move levels: progression + display

**Relevant files:**
- `systems/combat_rounds.gd` (Feint effect, damage path, beat emission)
- `data/combat_rounds.json` (Feint level table, beat strings)
- `scenes/components/combat_director.gd`, `scenes/components/combat_stage.gd` (autoguard / retaliate beats)
- `tests/test_combat_rounds.gd`
- `scripts/sim_combat_balance.gd`
- REFERENCE §3.7b Moves, Damage

**Status:** ready-for-agent

- [ ] Damage bonus scales with Feint level; ends when the opening ends
- [ ] Autoguard only when last resolved action was Feint; fires at most once per incoming hit at the stated chances (seeded tests at L3/L4/L5)
- [ ] L5 retaliate: free Strike at the attacker, no action spent, can follow an autoguard; doesn't trigger off itself or chain
- [ ] Retaliate XP: counts as a Strike use for move XP (or decide + note)
- [ ] Transcript line + beat per passive firing
- [ ] REFERENCE updated; sim re-run, result noted in the commit
- [ ] Human check: autoguard/retaliate beats read clearly on device

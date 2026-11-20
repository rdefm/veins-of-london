# 14 — Combat sight: Time fog cut, Life HP numbers, Emotion targets

**What to build:** Spec `.scratch/lenses/spec.md` "Sense L3: combat sight". For the player with lens + Sense >= combat gate: Time multiplies enemy `unreadChance` by `1 - timeFogCutByTier[tier]`; Life shows enemy `hp/hpMax`; Emotion shows an unread action's target. Contact Dials: a Time lens applies the fog cut to that ally's AI reads only (ally plans read fogged intents, R§3.7b Round); Life/Emotion do nothing for contacts. Fog stays seeded off `fogRngState`; a lens changes the threshold, not the stream.

**Blocked by:** 01

**Status:** ready-for-agent

**Relevant files:**
- `systems/combat_rounds.gd`
- `systems/lenses.gd`
- `data/dial.json`
- `scenes/components/combat_stage.gd`
- `scenes/screens/combat_rounds.gd`
- `tests/test_combat_rounds.gd`
- `docs/REFERENCE.md` §3.7b Fog

**Acceptance:**
- [ ] Unread rate drops with a Time lens (seeded test); unchanged without.
- [ ] HP numbers / unread targets shown only with the right lens + gate.
- [ ] James with a Time lens: his reads see more intents. Human QA: strip display.
- [ ] Syntax check clean, tests pass; REFERENCE/CODEMAP updated for this ticket's part.

# 05 — Arnie vs Archie demo: voiceover, HP, clear beats

**What to build:** Make the Arnie-vs-Archie demo readable. The intro cards set it up ("the more you practise a move, the better you get at it. Eventually you'll be able to do much more with it too. Watch this."), then cut to the fight. Arnie voices over each beat of the existing Level-5 Feint demo: what he's doing, what the low-level version would do, and what his level adds (autoguard, retaliate). Both fighters' HP is visible throughout. Each notification (feint, autoguard, retaliate) reads clearly. Follow `docs/writing-guide.md`; flag PROSE-REVIEW.

**Blocked by:** 04 — Gym practice fight is a real tutorial (shares coach/explanation plumbing).

**Relevant files:** `data/events/gym.json` (watch → `start_demo_fight`, cards around resumeCard 8), `systems/combat.gd` (`start_demo_fight`), `systems/combat_rounds.gd` (demo-fight rounds/procs, coach marks), `scenes/screens/combat_rounds.gd` (Readouts/HP display), `scenes/components/combat_transcript.gd`, `scenes/components/turn_order_strip.gd`, `docs/writing-guide.md`; REFERENCE.md §3.7b Move levels.

**Status:** ready-for-agent

- [ ] Intro prose before the demo explains move levels and says "watch"
- [ ] Arnie's voiceover line shows for each demo beat
- [ ] Arnie's and Archie's HP is visible during the demo
- [ ] Feint/autoguard/retaliate lines state plainly what happened
- [ ] Post-demo card no longer repeats what the voiceover already covered
- [ ] New prose flagged PROSE-REVIEW
- [ ] Headless test: demo beats carry voiceover lines; HP readout present for both combatants

# 02 — Opening moves: Feint, Stun, Lure/Exposed, Leg it

**What to build:** The rest of the prototype move set, so the player can make openings instead of only waiting for them, and escape. Feint opens a Guarded target. Stun interrupts an Open target. Lure baits an attacker into a forced opening (Exposed). Leg it flees. Each action picks its own target. The move palette explains why an invalid plan can't be committed. Spec: `.scratch/combat-revamp/spec.md` (User stories 18–24, 35; Implementation Decisions: Moves as data, Stun and freeze removal, Vocabulary → Exposed; Further Notes defaults).

**Blocked by:** 01 — Tracer: replace old prototype with Guard/Strike 1v1

**Relevant files:** `systems/combat_prototype.gd`, `scenes/screens/combat_prototype.gd`, `data/combat_prototype.json`, `autoload/GameData.gd` (`_validate_combat_prototype`), `tests/test_combat_prototype.gd`, `CODEMAP.md` (if responsibilities change). Existing flee chance 0.65: see `systems/combat.gd` / `data/constants.json`, REFERENCE §3.7.

**Status:** ready-for-agent

- [ ] Data rows for `feint`, `stun`, `lure` (cost 2), `legIt` per the spec's move table; validation covers them
- [ ] Feint: Guarded target → Open until its next Guard; actor's guard state unchanged; no-op on an Open target
- [ ] Stun: on an Open target removes its next 1 action (dropped from timeline; target's guard state unchanged) and leaves the actor Open; on a Guarded target fizzles with no effect
- [ ] Lure: occupies 2 action positions, actor Guarded while active; the first enemy to attack the actor becomes Exposed (counts as Open; its own Guard can't clear it) through the end of next round; Lure then ends and the actor is Open, so a second attacker hits full
- [ ] Leg it: flee roll (draft 0.65); success ends the fight `fled`; either way the actor's remaining actions that round are lost; failure leaves the actor Open
- [ ] Per-action target selection for enemy-targeted moves; block reasons surfaced for invalid plans
- [ ] Beats for feint, stun, fizzle, exposed, flee success/failure
- [ ] Tests: Feint→Strike on Guarded = full; Feint on Open = no-op; Stun on Guarded fizzles; Stun on Open removes next action and target stays Open; Lure first attacker Exposed (its Guard doesn't restore guard), second attacker hits Open player; Guard, Guard, Leg it → no full hits taken that round, success = `fled`, failure = Open + no further actions
- [ ] Screen: palette offers all moves with target pickers; Lure fills two positions; block reasons visible
- [ ] Check/lint clean; suite passes; new prose flagged `PROSE-REVIEW:`

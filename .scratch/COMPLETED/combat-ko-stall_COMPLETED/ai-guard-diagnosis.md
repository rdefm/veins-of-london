# Combat AI over-guarding — diagnosis

Sim: `scripts/sim_ai_guard.gd` (n=200 seeded fights/setup, fog on, real Archie, player = always-Strike or always-Guard). Columns: S/G/F = Strike/Guard/Feint share of actions.

## Numbers (always-Strike player unless noted)

| Setup | Ally S/G/F % | Enemy S/G % | Rounds (mean) |
|---|---|---|---|
| mugger + Archie | 46/36/17 | 52/48 | 2.0 |
| 2 muggers + Archie | 48/38/14 | 50/50 | 3.7 |
| bruiser + turtle + Archie | 46/38/16 | 51/49 | 3.6 |
| turtle + Archie | 44/22/34 | 34/66 | 2.0 |
| L3 hard mugger + Archie L3 | 34/58/7 | 53/47 | 4.1 |
| L5 2 bruiserV2 + turtleV2 + Archie | 14/85/1 | 66/34 | 3.5 (player loses 100%) |
| all-guard mugger + Archie (passive player) | 47/11/42 | 0/100 | 5.2 |

Passive (always-Guard) player: 2 muggers + Archie L3 stalls up to the 61-round cap in ~20% of fights.

## Findings

1. **Premise only partly true.** L1-L2, 1-2 enemies, active player: ally guards ~36-38%, fights 2-5 rounds. Not "almost every action".
2. **Root cause: threat rule dominates.** `_ally_action` (combat_rounds.gd ~1121) guards if ANY read enemy action at the same index aims at the ally (damage/stun). Enemies target uniformly over player + living allies, so P(threat) = 1-(1-p)^n grows with enemy count. 3 enemies: ally guards 80-89%. Player KO'd: ally is sole target, 100%. Threat guards are ~60-95% of all ally guards in every setup. The rule fires before the "strike if Open" check, so Archie never trades even when an enemy is Open.
3. **Chip-strike fallback is minor.** `allyChipStrikeChance` 0.3 -> 0.6 -> 1.0: ally guard share 36% -> 30% -> 21% (mugger+Archie); threat guards unchanged; L5 stays 80%+. Number alone won't fix it.
4. **Enemy guarding is pattern-driven, by design.** mugger 50%, bruiser ~34%, turtle ~66% guard per pattern weights. There is no enemy auto-guard reply: `_autoguards` is the Feint passive (Open target whose last move was Feint), not enemy AI.
5. **No hard deadlock.** Enemy all-guard vs Archie (L1 and L3, hard mugger): Archie Feints then Strikes, fights end in 2-9 rounds, no timeouts. Soft stall needs a player who only guards: Guard levels up to L3 block-chance, making them near-immortal (sim artifact). Ally has no Feint path when it has no action after the current one, falling back to 30% chip.

## Fix options

- **A. Strike-when-Open before threat-guard, HP-gated.** Order: Strike an Open enemy unless ally hp < X% (then Guard on threat). Biggest effect on multi-enemy fights. Touches REFERENCE.md §3.7b "Ally AI" sentence (line ~857; Guard-first order) and would add one data number (hp threshold, next to `allyHealBelow`). Risk: Archie dies more; tune X.
- **B. Probabilistic threat guard.** Guard on threat with chance `allyThreatGuardChance` (e.g. 0.6), else fall through to Open/Feint/chip rules. Smaller change, new data number; same REFERENCE line. Less predictable to read.
- **C. Raise `allyChipStrikeChance`.** Data-only (0.30 -> ~0.6); REFERENCE.md line ~857 and data/combat_rounds.json line 9. Cuts 1-2 enemy guard share ~6-15 pts, does nothing for 3+ enemies / post-KO.

Recommendation: A (optionally with C). Human picks before ticket 04.

## Decision

Human picked **Option A** (Strike an Open enemy before the threat-guard check, HP-gated).

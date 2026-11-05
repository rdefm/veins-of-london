# London market balance report (ticket 11)

Sim: `godot --headless -s scripts/sim_faction_economy.gd -- days=60 seed=N every=0`, seeds 1-3, stats days 31-60. Before = ticket 01 baseline (pre-market code, re-run at 78b04f02). After = this ticket's tree. **Not all targets met. Needs human sign-off / decision (see Open).**

## Changes
| file | key | before | after |
|---|---|---|---|
| data/market.json | oreConversionRate | 0.1 | 0.012 |
| data/market.json | ore civilianDemand (normalStock = 14x) | 160/160/160/135/190 | 120/120/120/100/140 (time/phys/life/fate/emo) |
| data/factions.json | roster-tail sellQuota | 3 | 36 |
| data/factions.json | Pan recipes sellQuota | 15-16 | 56 |
| data/vein_growth.json | factionPruneThreshold | 85 | 65 |
| data/vein_growth.json | factionYieldMult (NEW, faction prune yield only) | n/a (1.0) | 1.7 |
| systems/faction_sim.gd | `_prune` multiplies yield by factionYieldMult | | |

Why: at tuned-down defaults ore sat at 4x max with zero stock. Derived ore demand (0.1 rate) alone was ~2,900/day. Harvest is regrowth-limited, not action-limited (doubling actionsPerBlock changed nothing), and `yieldPerPoint`/drift are shared with the player (and hard-coded in tests), so a faction-only `factionYieldMult` supplies the +15-20% harvest the spec estimated (actual: harvest ~1,690 -> ~2,900/day).

## Before / after
| metric (seed 1/2/3) | target | before | after |
|---|---|---|---|
| Item named share | 65-75% | 47 / 48 / 47 | 49 / 58 / 56 |
| Ore named share | near baseline (52/66/60) | 52 / 66 / 60 | 73 / 75 / 66 |
| Items under 50% named (of 43) | few | ~34 | 23 / 15 / 17 |
| Days pinned min/max (goods, of 30) | none | none | s1: time min 29, physics max 31, life max 26; s2: emotion max 4; s3: fate 4, emotion 11 |
| Faction shortfall days (worst) | none permanent | conclave 1 | conclave rejuvenation 14/30 every seed, failsafe 6-8; firm navvysDraught 9 (s1) |
| Turf (min control / presence, final leader) | healthy | identical | identical (firm 23% leader, no zero-turf) |
| War endings | healthy | quiet1+truce1 / same / truce2 | quiet2+truce2 / same / truce2+quiet1 |

Faction wallet growth (£/day, reported only):
| faction | before s1 | after s1 | after s2 | after s3 |
|---|---|---|---|---|
| collective | +1,953 | +9,544 | +17,626 | +7,724 |
| firm | +1,068 | +8,740 | +13,962 | +20,124 |
| guild | +14,340 | +35,361 | +39,706 | +42,623 |
| network | +7,552 | +29,634 | +28,005 | +33,206 |
| conclave | -774 | +10,348 | +18,870 | +7,658 |

Withholding vs single sale (Market seam, fresh state, no named supply so a control drifts +77% ore / +58% item over 7 days): one 100-ore sale moves ore price -1.3% (75->74); 10 Time Pearls move 0%. Withholding 40 ore/day for 7 days reaches 173 vs control 133 (+30% over control); 80/day reaches 245 (+84%). Item buy-up 3/day: 219 vs 189 (+16%); 6/day: 258 (+36%). Single sale is invisible, sustained control is material.

## Open (needs human)
1. **Item named share 49-58%, not 65-75%.** Limit is Life (and Fate in some seeds): nobody harvests enough Life (only the Collective). Rejuvenation/Failsafe/Good Year/Healing Burst need Life, so Guild/Conclave can't craft them (Conclave short on Rejuvenation every seed). Options: more Life veins for Guild/Conclave, Life harvest bonus, or drop Life from those recipes. Keystone has no crafter (0%).
2. **Per-ore overshoot/undershoot by seed** (time at min in s1, physics max in s1: Firm hoards Physics into its large quotas). A per-ore harvest mult or per-faction quotas would fix; `factionYieldMult` is a single global.
3. Ore named share overshoots baseline (73/75/66 vs 52/66/60) since faction harvest rose ~70%.
4. Wallets grew 3-8x vs baseline (not fixed, per ticket).
5. `factionYieldMult` is a new mechanic knob; confirm or replace.

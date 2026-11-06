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

---

# Ticket 14 — targeted veins + Independents share

Sim as above, seeds 1-3, days 31-60. Before = ticket 11 tree (factionYieldMult 1.7). After = this ticket. **Not all targets met — see Open.**

## Changes
| file | key | before | after |
|---|---|---|---|
| data/vein_growth.json | factionYieldMult | 1.7 | removed (code + test + REFERENCE.md) |
| data/market.json | independentsOreShare | 0.4 | 1.5 |
| data/market.json | independentsShare (items) | 0.3 | 0.1 |
| systems/factions.gd `DAY_ONE_ROSTER` | Guild ores (9 veins) | time 6 / physics 3 | time 5 / life 2 / physics 2 |
| systems/factions.gd `DAY_ONE_ROSTER` | Conclave ores (11 veins) | fate 6 / time 4 / life 1 | fate 3 / time 5 / life 3 |

Roster change swaps ore types inside existing groups only: vein counts and districts unchanged, so no turf/siteCap/presence/claim-weight change. Roster stays a code constant (not moved to data; not asked).
Iterations: ore share 0.6/1.0 with items 0.3 -> item named 47-52%; item share 0.15 -> 57-62% but shortfalls return; 0.1/1.5 -> 70-74% but Conclave rejuvenation short 14/30 (Time starved after Guild swapped time->life); fix = Conclave fate->time, Guild physics->time.

## Before / after
| metric (seed 1/2/3) | target | before | after |
|---|---|---|---|
| Item named share | 65-75% | 49 / 58 / 56 | 70 / 75 / 72 |
| Ore named share | relaxed | 73 / 75 / 66 (baseline pre-market 52/66/60) | 19 / 15 / 18 |
| Conclave rejuvenation short days (of 30) | not permanent | 14 / 14 / 14 | 0 / 4 / 2 |
| Conclave failsafe short days | not permanent | 7 / 8 / 6 | 0 / 1 / 4 |
| Ore days pinned max | none | time min 29, physics max 31, life max 26 (s1) | s1 physics 8, fate 5; s2/s3 none >= 5 |
| Items pinned max >= 5 days | none | not tabulated | no-crafter items 31 (keystone, cleanSlate, heavyMetal, skeletonKey, goodYear); s1 also blackHole/healingBurst/deadweight/signalFailure/dejaVu/navvysDraught 31; s2 healingBurst 26, happyAccident/secondImpression 29, nostalgia 31; s3 dejaVu/nostalgia 31 |
| Turf | healthy | firm 23% leader, no zero-turf | identical (firm 23%, no zero-turf) |
| War endings | healthy | quiet2+truce2 / quiet1 / truce2+quiet1 | quiet2+truce2 / quiet1 / quiet2+truce1 |

Faction wallet growth (£/day, reported only; end of run):
| faction | before s1/s2/s3 | after s1 | after s2 | after s3 |
|---|---|---|---|---|
| collective | +9,544 / +17,626 / +7,724 | +14,334 | +15,927 | +15,732 |
| firm | +8,740 / +13,962 / +20,124 | +15,607 | +32,188 | +31,468 |
| guild | +35,361 / +39,706 / +42,623 | +53,622 | +61,322 | +73,141 |
| network | +29,634 / +28,005 / +33,206 | +50,804 | +51,909 | +53,465 |
| conclave | +10,348 / +18,870 / +7,658 | +25,919 | +20,167 | +13,923 |

## Open (needs human)
1. **Ore named share 15-19%** (relaxed on purpose; ticket 11 had 66-75%). Factions harvest ~2,000 ore/day, Independents ~1,800; most ore is bought from Independents. Sign off the figure.
2. **Pinned items remain** (max price): items with no faction crafter (Keystone, Clean Slate, Heavy Metal, Skeleton Key, Good Year) are pinned at max every seed (31/31 days). Good Year is not craftable by anyone. Needs a crafter or recipe decision.
3. **Network short on Déjà Vu 9/30 days every seed** (needs Fate; Network owns 1 Fate vein); Firm Smelling Salts 6-8 days (s1, s3); Guild Stutter/Invisibility 5 days (s1, s3).
4. Wallet growth is up 2-4x vs ticket 11 (fewer faction-held-ore costs, Independents ore sales). Reported, not fixed.

## Ticket 15 — craft loop skips uncoverable recipes

Seeds 1-3, days 31-60. `craft()` already iterates every recipe and `_craft_toward_target`'s early `return` only ends that recipe's attempts, so the starved-first-recipe case was already handled. No code change; test added to pin it. Sim output (wallet growth, shortfall days, byItem) is identical to the ticket 14 "after" columns, so named-share and shortfall deltas are zero.

## Ticket 18 — outside-craft tuning (NOT met; no data change committed)

Sim seeds 1-3, days 31-60. Baseline = tree after ticket 17. Variants tried (data only, reverted):
- B: `dailyCap` 2 -> 8 all factions.
- C: B + `maxBuyMult` 2.0 -> 4.0 (factions.json, temporary probe).
- D: B + `tierPenalty` 1 -> 3.

| metric (s1/s2/s3) | target | baseline | B cap 8 | C +maxBuy 4 | D +tierPen 3 |
|---|---|---|---|---|---|
| Item named share | 65-75% | 70/75/74 | 70/73/72 | 70/73/72 | 69/74/72 |
| Goods pinned max >=5d (excl Keystone) | 0 | 16/9/12 | 18/16/10 | 24/14/21 (+all 5 ores pinned max) | 17/10/13 |
| Conclave short days (of 30) | not permanent | 2/13/11 | 2/10/9 | n/a | n/a |
| Network short days | not permanent | 7/6/9 | 1/6/2 | n/a | n/a |
| Turf / leader | healthy | no zero-turf, firm 23% | same | same | same |

Always pinned at max in every seed and variant: goodYear, skeletonKey, cleanSlate, heavyMetal, navvysDraught, happyAccident, secondImpression, dejaVu (mostly), plus blackHole/deadweight/signalFailure/stutter in s1.

**Diagnosis:** binding constraint is London ore, not the outside-craft knobs. Physics/life/fate/emotion close at 3-4x base most days, above the factions' `maxBuyMult` 2.0 gate, so `_buy_outside_ore` refuses. Lifting the gate (C) just drains ore and pins all five ores at max. Cap and tier penalty barely move units made (a few per good per run vs ~7.8/day nameless demand each).

Wallet growth (reported, not fixed): unchanged from ticket 14 order of magnitude, guild/network +50-70k/day, collective/conclave +14-25k/day.

Not done: per-ore specialist reserve (no evidence outside buyers starve specialists: specialist shortfalls unchanged or lower with cap 8), rename question.

**Open (needs human):**
1. Targets "no pinned good" unreachable with listed knobs: ore supply is ~20 pinned goods short. Options: (a) accept pinned for low-value/no-crafter goods, (b) raise ore supply (independentsOreSupplyMult / yields), (c) drop recipes' ore cost or demand for those goods (`civilianDemand`), (d) give outside craft its own buy gate.
2. Rename `independentsOreShare` -> `independentsOreSupplyMult`? (asked, not done).

### Ticket 18 follow-up experiments (reverted, not landed)

Seeds 1-3, days 31-60.
- **E: factions apply Good Year to veins** (want 0.5/vein, 3 applications/day, highest tier, bought via normal shortfall buying). Borrowed Time has no vein effect (banks player time blocks), not tried. Result: Good Year still pinned max 31/31 days every seed, <0.5 units/day made (5 fate + 5 life at 0.20 base success is ore-expensive in an ore-short market). Faction ore harvest 1799/2294/2215 -> 1861/2242/2167 per day (noise). Pinned goods 18/8/12 (baseline 16/9/12). **No effect.** Code reverted.
- **F: `independentsOreShare` 1.5 -> 2.0** (validator max). Independents ore 1714/1816/1795 -> 2245/2350/2292 per day; factions unchanged. No ore pinned at max any seed (baseline physics 8/5/6 days). Goods pinned max >=5d (excl Keystone) 11/5/6 (baseline 16/9/12): left are blackHole, deadweight, signalFailure, skeletonKey, goodYear, heavyMetal, navvysDraught, cleanSlate (s1); dejaVu, skeletonKey, goodYear, heavyMetal, cleanSlate (s2/s3). Item named share 74/78/77 (target 65-75: s2, s3 over). Ore net +470-510/day surplus. Turf unchanged.
- **G: F + `dailyCap` 8**: pinned 12/5/6, named 73/78/75; Network short 5/5/9 days, Conclave 3/2/12. No gain over F.

### Ticket 18 — faction boost experiments (working tree, NOT committed; awaiting human)

Mechanic added: factions buy/hold Good Year + Borrowed Time (`vein_growth.json factionBoosts`, `FactionSim.apply_good_year/borrow_actions/boost_want`); Borrowed Time adds `extraActions` fieldwork actions per unit spent (prune = ore). Seeds 1-3 days 31-60, ore share 1.5, dailyCap 2.

| run | change | faction ore/day s1/s2/s3 | Independents % of ore | named item% | pinned goods >=5d (excl Keystone) |
|---|---|---|---|---|---|
| baseline | - | 1799/2294/2215 | 48/44/44 | 70/75/74 | 16/9/12 |
| H | factionBoosts only (GY want .5, 3/day; BT want .3, 2/day, +3 actions) | 1835/2323/2253 | 48/44/44 | 70/75/73 | 14/12/15 |
| I | H + BT recipe time 8->4, base .15->.30; GY fate5+life5 ->fate2+life2, base .20->.35 | 1926/2328/2307 | 45/43/42 | 71/76/75 | 15/7/8 |
| J | I + GY ingredients life2+emotion2 (Collective has no fate), BT want .5, 3/day | 1961/2513/2357 | 45/40/42 | 72/76/74 | 16/7/9 |
| K | J + goodYear tierBump 1->2, factionRootFeedPerDay 1->3, BT +6 actions | 2411/2714/2781 | 39/37/37 | 75/76/76 | 12/10/9 |

Findings: Good Year was uncraftable (Collective owns no Fate vein, fate >2x maxBuyMult), so ingredient swap was needed. K: faction ore +34/+18/+26%, Independents 37-39%. Named share 75-76 (edge). Shortfalls: Network 5/8/9 days, Conclave 7/7/5. Changes touch player-facing data (recipes, tierBump).

### Ticket 18 — landed: faction boosts + Collective Fate vein + Conclave Good Year

Good Year recipe restored (fate 5 + life 5, 0.20). Collective: +1 Fate vein (Shoreditch, siteCap 7->8, +2 map stop slots). Conclave crafts Good Year. Borrowed Time recipe time 4 / 0.30.
| metric (s1/s2/s3) | baseline | after |
|---|---|---|
| Faction ore/day | 1799/2294/2215 | 2510/2837/3046 |
| Independents ore share | 48/44/44% | 38/36/34% |
| Collective ore share | 8/13/7% | 19/22/19% |
| Avg ore price x base | 2.58/2.77/2.71 | 2.38/2.39/2.33 |
| Avg item price x base | 2.77/2.45/2.54 | 2.73/2.40/2.35 |
| Item named share | 70/75/74 | 73/76/77 (s2, s3 over 75) |
| Pinned goods >=5d (excl Keystone) | 16/9/12 | 19/11/10 |
Shortfalls: Network 3/7/6 days, Conclave 0/1/8. Turf healthy (firm 23%, no zero-turf). Test `full_playthrough_tutorial_economy_ticks_and_save_roundtrip` fails on the original tree too.

Ticket 18 closed by human with open items accepted: item named share 73/76/77% (s2, s3 over 75), pinned goods 19/11/10 remain (blackHole, deadweight, signalFailure, skeletonKey, heavyMetal, cleanSlate, dejaVu, happyAccident).

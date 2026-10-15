# Balance sim report (ticket 30) — for human sign-off

Sim: `godot --headless -s scripts/sim_faction_economy.gd -- days=N seed=S every=0` now ends with a "turf" block
(controlled/present districts per faction every 10 days, flips, min/peak control, min presence, leader share,
permanent zero-turf factions). `run()` returns the summary; `quiet=1` skips the report.
Test `a_long_run_leaves_no_permanent_zero_turf_faction_and_no_runaway_leader` asserts it (seeds 1, 5; 120 days).

## Evidence (13 districts, player credits 25 life/day, rivalry on)
| run | flips | min control (col/frm/gld/net/ccl) | min presence | leader |
|---|---|---|---|---|
| seeds 1-3, 150d | 0 | 1/3/1/0/2 | 3/3/2/2/3 | firm 23% |
| seed 4, 400d | 0 | 1/3/1/0/2 | 3/3/2/2/3 | firm 23% |
| seed 5, 400d | 2 | 1/3/1/0/0 | 3/3/2/2/3 | firm 23% |

- No faction ever has zero presence; Network starts and stays at 0 controlled / 2 foothold. No runaway (leader 23% ≤ 60% cap).
- Seed 5: Firm takes 5 Conclave veins via rivalry raids (2 flips). Only turf churn seen.

## Finding: "turf changes hands over time" is NOT met by the sim
Map is static: sim has no player prospecting, so no unclaimed sites exist for NPC claim rolls (the only live-control
claim path), and faction-on-faction vein raids are rare (1 in 5 runs, up to 400d). Ticket criterion 1 cannot be
shown without a scripted player/prospecting actor, which I did not invent. Decision needed: add one, or accept.

## Not exercised by the sim (player-facing; no sim evidence)
Perks, harassment, grudges, warmonger, call for aid, ambush all key off player action. No values proposed from
data; current values left as-is. TBD markers untouched in REFERENCE.md. Candidate flag from code reading only:
`turf.footholdShare` 0.25 gives every faction presence in ~2-3 districts, which is why zero-turf never occurs.

## Proposed TBD changes
None backed by evidence. Recommend keeping all current TBD values until a player-actor sim exists.

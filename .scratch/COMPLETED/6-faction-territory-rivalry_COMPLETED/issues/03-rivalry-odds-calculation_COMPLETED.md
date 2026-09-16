# 03 — Rivalry odds calculation (resource/security disparity + relation matrix)

**What to build:** A new standalone function (e.g. `Factions.roll_rivalry_odds(attempt)`) that takes one attempt record (ticket 02's shape) and computes a success chance from three inputs: attacker vs. defender resource disparity (`state.factions[id].resources`, faction-resource-economy), the target vein's security tier `raidResist` (`data/vein_security.json`), and the current attacker↔defender relation (ticket 01's matrix). Exact formula and the direction relation feeds odds are left to the implementer to document in code — the PRD explicitly leaves the exact resource/security-disparity-to-odds formula as an open question — but the qualitative shape is fixed: higher attacker resources / lower defender resources increases the chance; higher `raidResist` decreases it; worse existing relation increases it (consistent with the PRD's "grudges compound" framing — a faction that already has bad relations with a rival is more exposed to further rivalry from them). The function rolls the computed chance and returns a resolved outcome (success/fail) for that attempt. It performs no state mutation — no ownership transfer, no relation write — that's ticket 04.

**Blocked by:** 01 (needs the relation matrix to read), 02 (needs an attempt record to score)

**Status:** ready-for-agent

- [ ] New standalone function computes a success chance for one attempt record from attacker/defender resource disparity, the target vein's `raidResist`, and current attacker↔defender relation — exact formula and relation-direction documented in code
- [ ] Function rolls the chance and returns success/fail per attempt — pure computation, no state mutation
- [ ] Higher attacker resource / lower defender resource increases success chance; higher target `raidResist` decreases it; worse existing relation increases it
- [ ] Chance is clamped to a sane probability range (never negative, never above 1) regardless of how extreme the inputs are
- [ ] Tests cover: fixed inputs at the extremes move the chance in the documented direction for each of the three inputs independently, clamping holds at extreme inputs
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean on every touched file; `scripts/run_tests.sh` passes

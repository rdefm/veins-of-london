# 15 — Network intel menu (player)

**What to build:** The Network handler sells a priced intel menu to the player:
- raid intel (planned moves against the player over the next 7 days)
- counter-raid warning subscription
- market intel (planned big buys/dumps)
- intel boost on a target
- privacy (the Network won't sell on the player for N days)
- disinformation on a rival, for N days: either inverted target choice or a strength overestimate that lowers its raid chance
- intel reduction (lower a rival's meter on the player)

Prices carry a small relation modifier, and some products are locked behind relation bands. The existing timed per-site intel (Collective questline) keeps working; the ticket decides whether it becomes one product or stays separate.

**Blocked by:** 04 — Escalation framework + raid rung; 14 — Intel meters.

**Relevant files:** `systems/network_handler.gd`, `systems/intel.gd`, `systems/faction_ai.gd` (planned-move reads), `data/constants.json` / `data/factions.json` (prices, gates), the Network handler UI (contacts/messages screens), `SaveManager` (privacy/disinfo timers), `tests/test_network_handler.gd`, `tests/test_intel.gd`, `tests/test_collective.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 86–87, 89–91, §Intel. REFERENCE.md §3.10.

**Status:** ready-for-agent

- [ ] Test per product: buying charges cash and applies its effect (meter up, a raid-intel message listing planned moves, timers set, rival meter down).
- [ ] Test: price changes with relation. A gated product is refused below its band.
- [ ] Existing per-site Network intel tests pass unchanged.
- [ ] The menu UI reads state and calls system functions only. Prices in JSON. REFERENCE and CODEMAP updated. `PROSE-REVIEW:` for handler lines.

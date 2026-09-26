# 10 — Unattended-proof taint and qualification

**What to build:** Each active contract period tracks whether the player helped. Helping = a manual delivery to that contract, crafting its requested recipe, cultivating/pruning any cultivator-assigned vein, unstashing the requested item/ore into shared stock, or buying the requested ore through any player purchase path. Sales' automatic purchases never taint. Settlements record `qualified` when a recurring, fully delegated, complete, untainted period settles after the Beat 6 flag (short first periods count).

**Blocked by:** 02 — Per-cultivator vein lists

**Relevant files:** `systems/contracts.gd` (deliver, settlement, period start), `systems/crafting.gd`, `systems/cultivating.gd`, `systems/stash.gd`, `systems/factions.gd`, `systems/archie_deals.gd`, `systems/vein_trade.gd`, `tests/test_contracts.gd`; spec §"Unattended proof".

**Status:** ready-for-agent

- [ ] `playerAssisted` per period, reset at each period start
- [ ] Set only by the five player actions, via their real public calls
- [ ] Sales automatic purchases (ticket 09's path, when present) never set it
- [ ] Period qualifies: recurring, delegated for whole period, `complete == true`, not assisted, settles after the Beat 6 flag
- [ ] Settlement record stores `qualified: bool`
- [ ] Tests: manual delivery disqualifies that period only; short first period qualifies; unrelated actions (other veins, other crafts, combat) leave it intact
- [ ] REFERENCE.md §2 and CODEMAP.md updated

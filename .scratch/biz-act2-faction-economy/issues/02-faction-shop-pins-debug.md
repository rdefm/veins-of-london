# 02 — Faction shop pins for Firm, Network, Conclave (debug-gated)

**What to build:** The Firm, Network and Conclave each get a shop pin on the map in their home district, like the Guild marketplace pin, opening that faction's shop (the Guild marketplace screen generalised to any faction). Each pin is gated by a per-faction shop-unlock flag. For now only Debug Start sets these flags, so the pins appear only on debug saves; later quests will set them. Guild and Collective access is unchanged.

Decision from ticketing (not in the original spec).

**Blocked by:** 01 — Faction holdings + real shops.

**Relevant files:**
- `scenes/components/map_canvas.gd` (guild pin ~line 687 via `MapLayout.faction_first_presence_anchor`, tap routing ~line 911)
- `scenes/screens/guild_marketplace.gd` (generalise to a faction id), `scenes/Main.gd` (screen routing)
- `systems/debug_start.gd` (set the unlock flags), `systems/economy.gd` (`can_buy_from_faction`)
- `autoload/GameState.gd` (new flags), `autoload/SaveManager.gd` (flag backfill)
- Tests: `tests/test_guild_marketplace_screen.gd`, map pin tests
- REFERENCE.md §2 flags; CODEMAP rows for map_canvas / marketplace screen

**Status:** ready-for-agent

- [ ] Per-faction shop-unlock flags exist for Firm, Network, Conclave, default false; backfilled on old saves
- [ ] Debug Start sets all three; a normal New Game shows no new pins
- [ ] With the flag set, a pin in the faction's home district opens that faction's shop, showing its real holdings
- [ ] Guild and Collective shop access unchanged
- [ ] Human on-device check listed in the report (pin placement, shop opens, buy/sell works)

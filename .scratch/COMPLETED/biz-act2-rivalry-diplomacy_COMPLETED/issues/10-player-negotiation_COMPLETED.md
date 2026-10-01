# 10 — Player negotiation

**What to build:** The player can make peace. A faction at its `offerPeace` weariness messages a peace proposal. The player can also propose peace through the key member, and it's accepted only if the faction's weariness is ≥ `acceptPeace`. A negotiation sheet sets truce length, vein transfers each way, and one-off and weekly cash each way. The faction scores each proposal and either accepts or makes one nearest-acceptable counter per round, for max 3 rounds. A failed or abandoned negotiation costs a little relation and starts a re-propose cooldown. At extreme player weariness the next enemy offer binds: the player can counter but not abandon, and can keep raiding until signing. On signing, vein swaps transfer. Weekly payments settle on Mondays with other bills; the ticket decides between the contract machinery and a dedicated obligation list.

**Blocked by:** 09 — Truce + faction–faction peace.

**Relevant files:** `systems/faction_ai.gd` (propose/counter/accept/abandon, answer offer), `systems/payroll.gd` / `systems/morning_accounts.gd` / `systems/contracts.gd` (Monday settlement), `systems/vein_trade.gd`, pending-message mechanism (`systems/collective.gd`), new sheet under `scenes/modals/`, `scenes/phone_apps/factions_app.gd` (Negotiate entry), `SaveManager`, `tests/test_faction_ai.gd`, `CODEMAP.md`. Spec: `.scratch/biz-act2-rivalry-diplomacy/spec.md` stories 49–55, 59–60. REFERENCE.md §3.1, §6.

**Status:** ready-for-agent

- [ ] Rollover test: a faction at `offerPeace` sends an actionable peace-offer message.
- [ ] Test: a proposal is refused below `acceptPeace`. An acceptable proposal signs a truce. A marginal one gets a counter. Round 4 is impossible. Abandon costs relation and sets the cooldown.
- [ ] Test: a binding negotiation (extreme weariness) can't be abandoned, and player raids stay allowed until signing.
- [ ] Test: weekly payments are collected on Monday. Vein swaps transfer on signing.
- [ ] The negotiation sheet reads state and calls system functions only. Negotiation state is saved and backfilled.
- [ ] REFERENCE and CODEMAP updated. `PROSE-REVIEW:` for peace offers and negotiation lines.

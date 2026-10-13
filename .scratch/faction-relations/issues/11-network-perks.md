# 11 — Network perks

**What to build:** Friendly: daily intel gain on one faction the player chooses. Partner: forewarnings of raids from all factions (reuses the partner warning path). Sworn: the player can commission a Network market move (sellIntel / priceGouge / disinformation) against a chosen target.

**Blocked by:** 07 — Perks core

**Relevant files:** `systems/perks.gd`, `data/faction_perks.json`, `systems/intel.gd`, `systems/partners.gd` (warnings), `systems/network_handler.gd`, `systems/faction_ai.gd` (Network moves), `systems/market.gd`, `scenes/screens/factions.gd` / `scenes/components/contact_cards.gd` for the choose/commission UI, tests: `test_intel`, `test_partners`, `test_network_intel_menu`, `test_perks`. REFERENCE.md Perks §, §3.1 "Intel".

**Status:** ready-for-agent

- [ ] Player can pick (and change) the watched faction; intel on it rises daily while Friendly+
- [ ] Partner: raid warnings from every faction's planned raid moves
- [ ] Sworn: commission action with cost/cooldown runs the chosen Network move against the target
- [ ] Tests through public intel/warning/move functions; UI QA list in the report

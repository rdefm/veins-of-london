# 01 — Multi-target crafted units never appear in inventory or sell

**What to build:** Crafting with "multi target" ticked (e.g. 100+ Blast) must put the units somewhere the player can see, use and sell. Today they land under a parallel `_multi` inventory key that no list shows; only non-multi crafts appear. Show multi units in the same lists as normal ones, as separate rows tagged "(multi)" (e.g. "Blast (multi)"), in inventory and the sell screen. Check every multi-craftable recipe (blast, shield, healingBurst, panic, panger, pandemonium, pansRapture; blackHole is always-multi). Decide with a test whether selling multi units is allowed/priced like single; if the sell path can't price them, price at the base recipe price.

**Blocked by:** None — can start immediately

**Relevant files:** `systems/crafting.gd` (MULTI_SUFFIX, inventory_key, attempt_craft, attempt_craft_batch), `systems/economy.gd`, `systems/consumables.gd`, `systems/loadout.gd`, `data/constants.json` (loadout.multiTarget), inventory/sell screens under `scenes/` (grep `_multi`), `scenes/modals/lab_bench_confirm_modal.gd`, `CODEMAP.md`

**Status:** ready-for-agent

- [ ] Headless test: batch-craft with multi=true → units listed by the inventory read used by the UI, tagged multi
- [ ] Multi units appear on the sell screen and can be sold; cash and stock update correctly
- [ ] Non-multi crafting/selling behaviour unchanged
- [ ] Human check: craft Blast with multi ticked, see "Blast (multi)" in inventory, sell some

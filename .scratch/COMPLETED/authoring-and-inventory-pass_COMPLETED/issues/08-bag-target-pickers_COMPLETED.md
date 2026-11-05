# 08 — Bag target pickers

**What to build:** Target items are used from their Bag row through a picker: veins for boosts and vein Deadweight, plus HQ for Deadweight, contacts for Smelling Salts, and grudges for Clean Slate. All of it calls the existing apply functions. The old separate Use block is removed.

**Blocked by:** 07

**Relevant files:** `scenes/components/bag_drawer.gd`, `systems/bag.gd`, `systems/cultivating.gd`, `systems/contacts.gd`, `systems/grudges.gd`, `docs/adr/0007-use-item-on-a-place.md`, `tests/test_bag.gd`, `tests/test_bag_drawer.gd`

**Status:** ready-for-agent

- [ ] Root Feed, Good Year and Deadweight can be used from the Bag through a picker
- [ ] Deadweight offers HQ as well as veins
- [ ] Smelling Salts offers contacts and Clean Slate offers grudges
- [ ] Use is hidden when no valid target exists
- [ ] The picker works with stashed-only stock
- [ ] The old Use block is gone with no item losing its action
- [ ] Human QA block lists the picker flow

# 11 — Seed a Dial without a haft

**What to build:** The player's Dial is always the umbrella. Nobody picks it, and it's never offered as an option. The unseeded Dial screen stops offering six "Seed as …" haft buttons. The player picks the first Lens ore and presses a single **Seed** button. Seeding takes only the Lens ore, and a newly seeded Dial stores no haft. Cost, success roll and failure behaviour are unchanged.

**Blocked by:** None — can start immediately.

**Relevant files:**
- `systems/dial.gd` (`attempt_seed`, `new_dial`)
- `scenes/screens/hq_dial.gd` (`_build_unseeded`, `_on_seed_pressed`; the success notification names no haft)
- `tests/test_dial.gd`, `tests/test_hq_dial.gd`, and every test calling `attempt_seed(<haft>, <ore>)` (about 60 calls; grep for `attempt_seed(`)
- REFERENCE §3.5 "Dial seeding", §1.4 `data/dial.json`

**Status:** ready-for-agent

- [ ] Unseeded screen: ore picker + one Seed button (disabled until an ore is picked); no haft buttons
- [ ] Seeding takes only the Lens ore; refusal reasons no longer mention a haft
- [ ] Newly seeded Dials carry no haft field
- [ ] REFERENCE §3.5 Dial seeding updated
- [ ] Tests updated and passing

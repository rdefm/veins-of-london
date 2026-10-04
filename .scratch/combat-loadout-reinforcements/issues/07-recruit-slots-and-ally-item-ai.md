# 07 — Recruit loadout slots and ally item AI

**What to build:** Combat-capable recruited contacts (Archie, James) get two personal slots in Profile with the same equip/unequip rules as the player; noncombat recruits show no loadout controls. Ally AI uses only its equipped items, following the existing guard-kit trigger and target rules; self effects apply to the acting ally. Allies may not equip Wormhole. Archie's built-in combat stash self-heal and its after-fight replenishment are removed. Settlement refill extends to allies: player first, then recruits in Profile order, slot 1 before slot 2. Ally action order is Dial cast (added in 10), equipped item, ordinary attack.

**Blocked by:** 06

**Relevant files:** `systems/contacts.gd` (combat kit / Archie stash), `systems/combat.gd` (ally turns), `systems/guard_kit.gd` (trigger rules to reuse), `scenes/phone_apps/profile_app.gd`, `autoload/SaveManager.gd`, `autoload/GameState.gd`, `data/constants.json` (Archie stash config), `tests/test_combat.gd`, `tests/test_contacts.gd`, `tests/test_phone_profile.gd`. Update REFERENCE §2, §3.7, §3.7a with the change.

**Status:** ready-for-agent

- [ ] Archie/James have two slots; noncombat recruits have none
- [ ] Wormhole cannot be equipped to an ally
- [ ] Ally uses only equipped items under guard-kit triggers; empty slots → attacks only
- [ ] No free Archie self-heal or replenish; old saves migrate cleanly
- [ ] Refill priority player → recruits (Profile order) → slot order, tested with scarce stock

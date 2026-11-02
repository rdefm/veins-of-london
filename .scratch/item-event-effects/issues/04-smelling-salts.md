# 04 — Smelling Salts (combat revive + KO cooldown clear)

**What to build:** In combat, Smelling Salts revives a KO'd ally at X HP. Out of combat, used from the Bag on a contact, it clears that contact's `koCooldownDays` (brainstorm §3.2).

**Blocked by:** 01

**Relevant files:** `systems/combat_rounds.gd`, `systems/contacts.gd`, `systems/bag.gd`, `data/combat_rounds.json`, `tests/test_combat_rounds.gd`, `tests/test_contacts.gd`; REFERENCE §3.7b, §3.10 Contacts, rooms, jobs.

**Status:** ready-for-agent

- [ ] Combat: only targets a KO'd ally; revives at the tier's HP
- [ ] Bag: only offered for contacts on KO cooldown; clears it and spends the item
- [ ] Guard-kit eligibility per the brainstorm

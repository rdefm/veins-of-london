# 44 — Archie as combat ally (vein defense)

**What to build:** Combat is currently strictly 1v1 — `combat` state holds a single `"enemy"` dict, not an array (`systems/combat.gd:210,221,250,296,416,472,618,704`), and `contacts.gd` has no ally/companion concept at all. Add Archie as a real second combatant in vein-defense fights: once Archie is recruited, he's always available to join (no relation threshold — per the human, defending shared interests doesn't need much trust). Mechanically, Archie acts as a genuine second attacker each turn alongside the player (not a passive stat buff), and he carries his own small consumable stash that replenishes between fights (independent of the player's inventory). He has his own HP pool — if it hits 0 he's knocked out and removed from that fight (or unavailable for some cooldown period), giving the mechanic real stakes without permadeath.

This is the foundational ticket for the ally-combat system — build the combat-state shape (allies, not just a single enemy) and Archie's participation generally enough that a future recruit can plug into the same system later (per the human: "Archie-only for now, but other characters will be recruitable in the same way later"), but only wire up Archie in this pass.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `combat` state extended to support an ally combatant (structure general enough for future recruits, not Archie-hardcoded at the schema level) alongside the existing single-enemy shape.
- [ ] When Archie is recruited and a vein-defense fight starts, player is offered (or automatically has) Archie join as a second attacker.
- [ ] Archie rolls his own attack each combat turn, using his own stats and his own small consumable stash (separate pool from player inventory, replenishes between fights — define replenish trigger, e.g. on fight end or daily tick).
- [ ] Archie has an HP pool; reaching 0 knocks him out of the current fight without ending the game/fight for the player, and makes him unavailable for a defined cooldown before he can be recruited into combat again.
- [ ] `docs/REFERENCE.md` updated with the new ally-combat state shape and Archie's stats/consumable constants.
- [ ] New tests covering: ally joins defense, ally attacks each turn, ally KO removes him from the fight without crashing/ending it, ally consumable stash depletes and replenishes correctly.
- [ ] Manual check noted for the human: trigger a vein-defense fight with Archie recruited, confirm he appears and fights, and confirm a scenario where he gets knocked out.

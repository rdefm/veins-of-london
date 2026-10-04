# 10 — Ally Dials and James's Dial grant

**What to build:** Dials become per-owner. Ally Dials use the player's mechanics for charge, daily regen, winding, Movement effects, capacity and cast XP/levels, replacing James's fixed three-casts-per-day rule. On recruitment James receives a level 2 Dial with a tier 1 Recharge Movement seated and tier 3 Time Pearl and Healing Burst loaded, charge full; his former fixed Rewind does not become an item or loaded Complication. Saves where James is already recruited gain this via migration without touching player stock. On an ally turn, eligible loaded Complications are tried first (same triggers/targets as items), then equipped items, then attack; reactive effects keep their timing. Only the player's seated Movement feeds out-of-combat attunement. Profile opens the shared Dial menu (08) for James. Archie gets no Dial.

**Blocked by:** 07, 08, 09

**Relevant files:** `systems/dial.gd`, `systems/contacts.gd` (James fixed Dial), `systems/combat.gd`, `autoload/GameState.gd`, `autoload/SaveManager.gd`, `data/constants.json`, `data/dial.json`, `scenes/phone_apps/profile_app.gd`, `scenes/screens/hq_dial.gd`, `tests/test_dial.gd`, `tests/test_contacts.gd`, `tests/test_combat.gd`, `tests/test_savemanager.gd`. Update REFERENCE §1.4, §2, §3.5, §3.7a with the change.

**Status:** ready-for-agent

- [ ] Fresh recruit and migrated save both give James the specified Dial at full charge; player stock unchanged
- [ ] Ally charge regen, winding, XP and levelling follow player rules; old 3-casts rule gone
- [ ] Ally turn order: Dial cast → item → attack (seeded test)
- [ ] Ally Movement does not affect player attunement
- [ ] Profile edits James's Dial through the shared menu

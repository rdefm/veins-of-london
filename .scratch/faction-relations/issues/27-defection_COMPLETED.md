# 27 — Defection

**What to build:** People are prizes too. When personal relation is ≥ `defectAt` and the member's faction is weak, or at war with the player and losing, a defection incident fires. On acceptance the member becomes a player contact and brings one of a vein, recipe or skill boost (TBD per member). The faction takes a relation hit and loses one perk-tier effect or `craftSkill`.

**Blocked by:** 24 — Key member model; 23 — Faction incidents

**Relevant files:** `systems/key_members.gd`, the incidents system from 23 (new `defection` trigger), `systems/contacts.gd` (`force_recruit`), `systems/vein_trade.gd` (handover), `systems/crafting.gd` (recipe), `systems/faction_sim.gd` (`craftSkill`), `systems/perks.gd`, placeholder event, tests: `test_key_members`, new defection test. REFERENCE.md key members §.

**Status:** ready-for-agent

- [x] Defection fires only when the gates hold; at most once per member
- [x] Acceptance moves the member to the player's contacts and grants the configured prize
- [x] Faction penalty applied (relation hit + perk-tier effect or craftSkill loss)
- [x] A defected member no longer counts for leadership
- [x] Placeholder card `PROSE-REVIEW`

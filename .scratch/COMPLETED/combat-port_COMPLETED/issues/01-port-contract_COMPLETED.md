# 01 — Port contract: REFERENCE §3.7b and mapping tables

**What to build:** The written contract the rest of the port implements. A new REFERENCE §3.7b ("Open/Guarded round combat") supersedes the combat parts of §3.7, §3.7a and §3.9. It carries over the prototype's rules and current draft values as production values (see spec Decisions), and adds:
- the per-fight XP lump: win 30, loss 3, Leg it 0;
- the Leg it rule (no parting shot, Blast boost kept);
- Rewind gating (consumable or Dial cast), Failsafe and the guard-kit rewind;
- carry-in rules for Prophet's Breath and Be a Lady.

It also drafts the tables needing human approval, each marked **DRAFT — pending sign-off**:
1. the archetype + plan patterns for every enemies.json template (muggers incl. harder and vein, raid guards/scrappers, territorial variants, faction squads, home raider);
2. the enemy-level table mapping the existing scaling drivers (vein value tier, faction strength, harder mugger, home raid) to Combat Skill level 1–5;
3. authored ally levels (contact combat-kit fallback, hired guards, hired muscle);
4. the action-model adaptation of Panic, Pan's Rapture, Panger, Pandemonium (anger/fury), Wormhole, Failsafe and disarm: what each does per action/round, its target and its guard effect;
5. how enemy/guard/raider kit items appear in a committed round plan and in fog.

Add the CONTEXT.md entries: Guard state (Open/Guarded), Exposed, Action, Round plan. Rewrite `.scratch/skill-level-cap-10/issues/03` so it also extends the actions-per-round, crit and fog curves to 10.

Docs only, no code. Per the consult-on-design-docs rule, don't mark the DRAFT tables decided: present them to the human and wait for sign-off before closing.

**Blocked by:** None — can start immediately.

**Relevant files:** `docs/REFERENCE.md` §3.7 Combat, §3.7a Squad combat, turn order, and Combat Skill, §3.8 Home-raid event chain, §3.9 Snapshots & Rewind; `CONTEXT.md`; `data/combat_prototype.json`; `data/enemies.json`; `data/hiring.json`; `data/recipes.json` (effectPower); `systems/combat.gd` (live item/status bodies to adapt); `.scratch/COMPLETED/combat-revamp_COMPLETED/spec.md`; `.scratch/combat-port/spec.md`; `.scratch/skill-level-cap-10/issues/03-extend-combat-curves-to-level-10.md`

**Status:** ready-for-human

- [x] REFERENCE §3.7b exists and states every rule and value the port needs; §3.7/§3.7a/§3.9 are marked superseded where they conflict
- [x] The five DRAFT tables are present and approved by the human
- [x] CONTEXT.md has the four new terms
- [x] Cap-10 ticket 03 covers the actions/crit/fog curves

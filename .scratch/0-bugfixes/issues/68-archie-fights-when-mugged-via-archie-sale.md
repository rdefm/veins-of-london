# 68 — Archie fights alongside player when mugged during an Archie sale

**What to build:** When the player is mugged while selling orichalchum through Archie, Archie is currently absent from the resulting fight — he only joins combat elsewhere via the normal recruited/kitted/not-KO'd gate. Since this mugging happens on his own deal going wrong, he should always fight alongside the player in this specific case, regardless of that gate.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] A mugging triggered specifically during a sale-via-Archie always includes Archie as a combat ally, even if he is not recruited, not kitted for combat, or on KO-cooldown.
- [ ] Muggings triggered outside the Archie-sale flow are unaffected — Archie's normal join gate still applies everywhere else.
- [ ] Combat resolves using the existing ally-combat mechanics (heal/attack behaviour, enemy targeting) already used for Archie elsewhere.
- [ ] Test coverage: mugging during an Archie sale includes Archie even when recruited/kit/KO-cooldown gate would normally exclude him; mugging outside that flow still respects the gate.
- [ ] Manual check noted for the human: get mugged while selling to Archie before he's recruited (or while on KO-cooldown) and confirm he still fights.

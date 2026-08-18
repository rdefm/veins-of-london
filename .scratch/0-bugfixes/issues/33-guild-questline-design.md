# 33 — Design a real Guild questline gate

**What to build:** Guild membership is currently mechanically identical to every other faction: `Factions.can_join("guild")` just checks `state.factions.guild.relation >= 40` (`data/factions.json`'s `joinRelation`). No Guild-specific scripted content exists — no dedicated flags, no event chain like Archie/James's tutorial (`data/events/james_meeting.json` etc.). "Joining requires demonstrated crafting ability and a sponsor" exists only as flavour text in `data/factions.json`, unimplemented. This ticket needs a design pass with the human before it's agent-buildable: what the questline's steps are, how far it should go before v1 ships, and how it interacts with the marketplace gate from ticket 29 (which currently ships against the generic relation threshold).

**Blocked by:** None to start the design conversation — but not implementation-ready until the human has scoped it.

**Status:** needs-triage

- [ ] Human has reviewed where other factions' relationship/tutorial content currently ends, to use as a reference point for scope.
- [ ] Questline steps and their gates (events, flags, relation thresholds) are decided and written up.
- [ ] Decision made on whether/how this ticket supersedes ticket 29's generic `joined` gate once it lands.
- [ ] Once scoped, this ticket is re-split into implementation-sized tickets (event content, state/flags, join-gate rewire) and re-labeled `ready-for-agent`.

# 09 — The 15 district events (content)

**What to build:** author and wire in all 15 events listed in D5 (`busker_greenwich` through `roman_brick`), including `conclave_watch`'s `excludeIfFlag: conclaveNoticed`. All prose drafted per CONTENT-GUIDE.md's tone bible.

**Blocked by:** 08.

**Status:** done

- [x] All 15 events present with their fixed ids and mechanics exactly as specified in D5
- [x] `conclave_watch` correctly excludes itself from the draw pool once `conclaveNoticed` is true
- [x] `busker_greenwich`/`pigeon_omen` one-shot effect flags behave as one-shot bonuses while the events themselves remain redrawable
- [x] `roman_brick`'s `oddities` counter increments correctly on repeat draws
- [x] Every new-prose file flagged `PROSE-REVIEW` in the task report
- [x] Tests: each event's mechanical effects (payment/roll/flag outcomes) covered
- [x] `godot --headless --check-only --script` clean on all touched files

## Comments

Implementation notes (M1-LONDON-T06):

- New engine primitives needed beyond ticket 08's scope, added here: `Events` effect ops `chance` (branching on/success/on_fail), `start_street_mugging` (new `event_mugging` combat context, routes back to the event screen on exit regardless of outcome), `npc_claim_best_unclaimed_site`, `lose_time_block`; `GameState.flags` gained `greenwichTipOff`, `luckyOmen`, `conclaveNoticed`, `oddities`; `SaveManager._restore_int_types` gained `flags.oddities`.
- `busker_greenwich`'s tip-off and `pigeon_omen`'s luck are one-shot flags consumed by the systems they affect, not by the event itself: `Sites.roll_tier()` consumes `greenwichTipOff` on the next Greenwich tier roll (+10 rich weight), `Economy.execute_sale()` consumes `luckyOmen` on the next sale (50% chance of +10% price).
- `rival_prospector`'s D5 wording ("any district with unclaimed sites") needed a real deck-engine change, not just a graceful no-op: added an optional `requireUnclaimedSiteInDistrict` field to the deck filter (`systems/district_deck.gd`), documented in `docs/M1-LONDON.md` D5, set only on this event.
- Code review (standards + spec sub-agents) caught: `soho_tout`/`rain`/`foxes` initially shipped as 2-3 cards despite D5 explicitly calling them "one card" — collapsed to single cards. Also deduplicated `Sites._worst_unclaimed_site`/`best_unclaimed_site`'s shared sort logic, and extracted `Combat.NON_LETHAL_MUGGING_CONTEXTS` to replace three copies of an inline `["mugging", "event_mugging"]` check.

**PROSE-REVIEW** (all new — draft per CONTENT-GUIDE.md tone bible, needs human audit):
`data/events/busker_greenwich.json`, `city_suit.json`, `camden_shakedown.json`, `heath_dogwalker.json`, `whitechapel_grief.json`, `kx_delay.json`, `soho_tout.json`, `battersea_hum.json`, `shoreditch_archie.json`, `conclave_watch.json`, `pigeon_omen.json`, `rain.json`, `rival_prospector.json`, `foxes.json`, `roman_brick.json`.

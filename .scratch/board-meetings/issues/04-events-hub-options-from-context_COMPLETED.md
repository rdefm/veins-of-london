# 04 — Events: hub options from a context-supplied list

**What to build:** a choice hub in an event can take its options from a list supplied in the event's context at start time, instead of only from authored options. Each generated option carries its text (tokens filled from context) and its effect. Generic and minimal — not board-specific — and authored hubs behave exactly as before. The hub's authored exit option still works alongside generated options.

**Blocked by:** None — can start immediately

**Relevant files:**
- `systems/events.gd` — `start_event()`, `start_or_defer()`, context / `fillFromContext`, hub handling (`_reenter_hub()`, `hub_exit_index()`)
- Event screen (see `CODEMAP.md`)
- `tests/test_events.gd` (prior art)
- Content lint / `tools/storyboard.html` if they validate hub shapes (see CODEMAP)
- Spec: §"Modules" → Meeting event

**Status:** ready-for-agent

- [ ] An event started with a context option list renders those options on its hub, tokens filled
- [ ] Choosing a generated option applies its effect and continues the event
- [ ] Authored hubs and existing events unchanged; existing events tests pass
- [ ] Snapshots / Rewind inside the event still work (context stays pure data)

# 01 — Engine: backward goto to a choice card

**What to build:** an option or card `goto` may target an EARLIER choice card (a "hub"), so a player can pick an option, see its response, and come back to the same choices. Re-entering the hub clears its resolved state and result text so it is selectable again. Forward-only gotos behave as before; a backward goto to a non-choice card stays an error. Rewind still restores correctly across loop visits.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/events.gd` (`_goto_target` ~300, `_visited_indices` ~322, `state.event.jumps`), `tests/test_events.gd`, REFERENCE.md §3.9a "Goto" (update the forward-only rule), `CODEMAP.md` if responsibilities shift. Needs human sign-off on the REFERENCE.md wording before _COMPLETED.

**Status:** ready-for-agent

- [ ] Backward goto to a choice card is accepted and moves the cursor there
- [ ] Re-entered hub is unresolved and shows no stale result text
- [ ] Backward goto to a non-choice card still errors
- [ ] Rewind snapshot taken mid-loop restores the correct card/state
- [ ] Revealed-card list stays sane across repeat visits (no duplicate cards)
- [ ] Tests cover hub -> answer -> hub -> exit

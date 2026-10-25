# 01 — Fix `james_dial_repair` event validation

**What to build:** `james_dial_repair` passes boot validation and content lint. Its cards carry the required `label` and `speaker` keys, and its `on_complete` uses an effect op the engine recognises. Currently the unknown `spend_quoted_calc` op and the missing card keys fail four tests. If `spend_quoted_calc` is meant to be a new engine op, that is a mechanics decision: STOP and ask the human rather than inventing it.

**Blocked by:** None — can start immediately.

**Relevant files:** `data/events/james_dial_repair.json`, `.scratch/writing-revamp/james-dial-repair-proposal.md`, `systems/events.gd` (op dispatch), `tests/test_event_content_lint.gd`, `docs/REFERENCE.md` §3.9 (events).

**Status:** ready-for-agent

- [ ] `schema_all_event_files_validate` passes
- [ ] `data_validates_and_every_trigger_resolves` passes
- [ ] `real_data_loads_and_validates` passes
- [ ] `content_lint_accepts_the_op` passes
- [ ] No new op or mechanic invented without human approval

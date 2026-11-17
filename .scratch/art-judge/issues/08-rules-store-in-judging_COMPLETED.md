# 08 — Rules store applied in judging

**Status:** ready-for-agent

**What to build:** A rules file in the shared `_judge` folder holds art rules:
```jsonc
{id, scope: {kind: "global"|"character"|"plate", name}, text,
 status: "proposed"|"accepted"|"rejected"|"retired",
 source: {eventId, draft, note}, createdAt, decidedAt}
```
When judging a draft, the accepted rules in scope are added to the judge's input:
- all global rules;
- character rules for the shot's cast;
- plate rules for its plate.

A rule the draft breaks shows up as a failed check that cites the rule id. Each judgement records `rulesHash` over the rules applied, so accepting, editing or retiring an in-scope rule makes exactly the affected judgements stale (picked up by batch judging).

In this ticket, rules are written by hand in the file. The tool UI comes in 09.

**Blocked by:** 03 — Batch judging and ranking.

**Relevant files:**
- `tools/art_judge/`
- `.scratch/event-art/_judge/` (new `rules.json`)
- `.scratch/event-art/<id>/board.json` (shot cast via `attach`, `plate`)
- `assets/character-references/` (character names for scope)

- [ ] Only `accepted` rules in scope reach the judge (verified via the fake backend's recorded request).
- [ ] A character rule reaches only shots with that character; a plate rule only shots on that plate.
- [ ] A broken rule shows as a failed check that names its rule id.
- [ ] Changing an in-scope rule makes only the affected judgements stale; out-of-scope ones stay current.
- [ ] Tests for scoping, staleness and status filtering.

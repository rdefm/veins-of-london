# 07 — Pub: Archie's questions as a conversation hub

**What to build:** The first live hub. In `pub`, after Archie sits facing the door ("You have about four questions"), the player gets a question hub: they can ask each question and hear Archie's answer, then advance with → when ready. Existing pub prose is reused and only lightly patched to fit the hub; any new lines are drafted against `docs/writing-guide.md` and `docs/CONTENT-GUIDE.md` and flagged `PROSE-REVIEW:`. One beat only — this ticket covers the questions hub, not the rest of the pub.

Ask the human before deciding the question list, which questions (if any) are `reselectable`, and the advance rule — those are writing decisions.

**Blocked by:** 05 — Conversation hubs: separate advance button.

**Relevant files:** `data/events/pub.json`, `.scratch/writing-revamp/pub-proposal.md`, `docs/writing-guide.md` (Hub loops, structure, characters), `docs/CONTENT-GUIDE.md`, `assets/events/pub/`, `tests/test_events.gd` or a pub-specific test, `tests/test_event_content_lint.gd`.

**Status:** ready-for-agent

- [ ] Question list, reselectable choices and advance rule agreed with the human before writing
- [ ] Pub plays the hub: questions answerable in any order, → advances per the agreed rule
- [ ] Prologue chain still continues to `buyer` after the pub
- [ ] Prose follows writing-guide; new prose flagged `PROSE-REVIEW:`
- [ ] Content lint and tests pass

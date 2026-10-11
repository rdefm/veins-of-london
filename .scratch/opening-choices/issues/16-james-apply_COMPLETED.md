# 16 — James meeting: apply approved choices

**What to build:** The James meeting plays as approved: the player chooses whether to tell James about the jar (James reveals more if told), and the pearl lesson is a choice of how to work, with the number of pearls owned afterwards equal to the pearls made.

**Blocked by:** 15 — James proposal (and owner approval); 03 — Item mods; 04 — Multi-attempt checks; 12 — Intro apply.

**Relevant files:** `data/events/james_meeting.json`, `.scratch/writing-revamp/james-meeting-proposal3.md`, `systems/events.gd`, opening scenario test file.

**Status:** ready-for-agent

- [ ] Event JSON matches the approved proposal; fixed 2-pearl grant removed.
- [ ] Tests: pearls owned = successes for each approach; "James watching" success raises per-attempt odds; tell vs hide recorded and James's lines differ; no odds change from telling.
- [ ] Existing `on_complete` effects (craftingUnlocked, James unlock, stage, Archie message) preserved.

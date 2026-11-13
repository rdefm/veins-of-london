# 14 — Prose: Archie → Arnie Security Office intro

**What to build:** The one-shot intro event fired on the next HQ visit after buying the Security Office. Archie says they need help with security and has called Arnie; Arnie walks the player through hiring (the weekly board), posting (Posts, + Assign, caps), Reserve (on call, answers alarms) and Costs. The Security screen works from the moment it ends — no chat-thread steps. Arnie appears nowhere else (no avatar or line on the board, no named venue, no system text naming him). Never replays, including after a room loss and re-buy. Written per `docs/writing-guide.md` (structure, humour, characters, audit) and `docs/CONTENT-GUIDE.md` tone.

**Blocked by:** 07 — Costs tab, Short Pay checklist, BizBrief links.

**Relevant files:**
- `docs/writing-guide.md`, `docs/CONTENT-GUIDE.md`
- `data/events/` (new event JSON), `systems/events.gd` (trigger from the room-purchase flag), `systems/home.gd` / `scenes/screens/hq.gd` (HQ visit hook)
- Prior art: existing intro events in `data/events/`, `tests/test_wren_introduction.gd`
- Tests: `tests/test_event_content_lint.gd`, a new intro test

**Status:** ready-for-agent

- [ ] Event fires once on the first HQ visit after buying the room; never again
- [ ] Covers hiring, posting, Reserve and Costs; no further steps required to use the screen
- [ ] Arnie named only inside this event
- [ ] Passes event content lint; tests address cards by key
- [ ] PROSE-REVIEW flagged: the whole event

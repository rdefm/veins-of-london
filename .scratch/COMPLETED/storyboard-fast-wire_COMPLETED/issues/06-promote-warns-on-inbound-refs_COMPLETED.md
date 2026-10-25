# 06 — Promote warns on other events pointing at this one

**What to build:** Promote's confirm lists every other event whose `choice` conditions point at the event being promoted, and warns when the new version no longer has a card key or option id one of them names. Warning only — Promote still proceeds on confirm.

**Blocked by:** 05 — Content lint in the storyboard tool.

**Relevant files:** `tools/storyboard.html` (`promoteBoard`, `promoteSummary`, Draft model), the refs file from 05, `tools/test_storyboard.js`.

**Status:** ready-for-agent

- [ ] Confirm lists inbound refs (event id → card key / option)
- [ ] Dropping a referenced key or option shows a warning naming the referring event (test)
- [ ] `node tools/test_storyboard.js` green

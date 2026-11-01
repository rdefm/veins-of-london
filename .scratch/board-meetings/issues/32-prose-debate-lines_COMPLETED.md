# 32 — Prose: debate lines (opener, responses, rebuttals, clashes, vote, chosen, concede)

**What to build:** Real prose for the generic debate block in `meeting.debate`, replacing ticket 30's placeholders. Three characters arguing what the business needs: all want it to succeed, they disagree on the lever. James: craftsmanship, proving the firm (and himself) better than the Guild. Archie: enough cash not to fear bills and to help others, so sales and share. Owen: timid, unsure, drifts to what he knows (more yield, more veins, a different ore). The player casts the deciding vote.

Cover: openers per voice; responses for every responder × pitcher × stance (back / challenge / wobble); rebuttals per pitcher; clashes for james|archie, archie|owen, james|owen (2-card pairs); vote prompt; chosen lines per pitcher; concede lines per voice. Several variants each; generic tokens only ({label}, {ore}).

**Principles (non-negotiable, from `debate-rework.md`):** replies answer a specific claim in the previous card; people say the numbers plainly (Owen hedges in manner, never withholds); no oblique images or lines needing a second read; justification follows the voice's motive; one beat per card, ≤ ~45 words; Guild only as a rival standard; no gardening vocabulary for Owen.

**Blocked by:** 30 — Debate skeleton and data model

**Relevant files:**
- `docs/writing-guide.md` (required), `docs/CHARACTER-VOICE-GUIDE.md` (Archie, James), `docs/CONTENT-GUIDE.md`
- `.scratch/board-meetings/debate-rework.md` (principles + worked sample)
- `data/board.json` — `meeting.debate`

**Status:** ready-for-agent

- [ ] Written against `docs/writing-guide.md`; passes its audit
- [ ] Every line makes sense after any generic pairing of tokens (sampled pairings shown in the report)
- [ ] Report flagged `PROSE-REVIEW:`

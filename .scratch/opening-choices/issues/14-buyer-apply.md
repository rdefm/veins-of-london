# 14 — Buyer (Marcus): apply approved choices

**What to build:** The buyer event plays as approved: the player makes their first trading decision, the haggle odds visibly include "You asked the right questions" / brave modifiers when earned, and the cash received matches the text on every path, including the split negotiated in the intro.

**Blocked by:** 13 — Buyer proposal (and owner approval); 12 — Intro apply.

**Relevant files:** `data/events/buyer.json`, `.scratch/writing-revamp/buyer-proposal.md`, `systems/events.gd`, opening scenario test file (from 12).

**Status:** ready-for-agent

- [ ] Event JSON matches the approved proposal.
- [ ] Tests: asked-questions raises Push odds (via odds query); cash granted equals text for take / push success / push fail / Archie / wants-half split.
- [ ] Time labels and `at` agree (lint green for this event if 08 landed).

# 100 — Archie deal offer shows its message before Accept/Decline

**What to build:** When Archie has a tag-along deal pending, the player currently sees only bare "Accept"/"Decline" buttons with no explanation of what they're agreeing to. The offer text already exists (generated in the deal-offer system, e.g. "Got a sale lined up, nothing of yours in it. Fancy tagging along for a cut?") but is never rendered anywhere — render it above the Accept/Decline buttons wherever this pending deal is shown (contact card and/or phone Messages), so the player reads the pitch before choosing.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] The deal's offer message text is visibly displayed above/alongside the Accept and Decline buttons everywhere the deal can be acted on.
- [ ] Accept/Decline behaviour itself is unchanged.
- [ ] Regression test confirming the offer text is present in the rendered output when a deal is pending.

PROSE-REVIEW: if the existing offer text needs adjusting for its new visible placement, redraft against CONTENT-GUIDE.md's tone bible and flag for human review.

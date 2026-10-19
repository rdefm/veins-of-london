# 17 — Sales cards: Decline button runs off screen

**What to build:** In BizBrief › Manage › Sales, the offer and contract cards push the Decline button past the right edge of the screen at phone width. Every card's content, including all action buttons, must fit inside the card at phone width. Fix the root cause in the shared card layout (likely a row whose children have a fixed or minimum width that can't shrink), not by nudging one button. Keep the compact layout from ticket 08 and keep drag-to-reorder working.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/components/contract_card.gd`, `scenes/phone_apps/bizbrief_app.gd`, `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Offer cards (Accept/Decline) and contract cards fit the phone width with no horizontal overflow
- [ ] Long item or counterparty names truncate or wrap rather than widening the card
- [ ] Drag reorder still works
- [ ] Human on-device: check Sales with a pending offer, a renewal offer and an active contract

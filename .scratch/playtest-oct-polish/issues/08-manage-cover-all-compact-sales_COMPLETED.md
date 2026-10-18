# 08 — BizBrief Manage: cover-all toggle + compact Sales cards

**What to build:**
- **Production:** a toggle at the top of the Production list sets "cover production" for every item at once. If all are on, tapping turns all off. If mixed or all off, tapping turns all on. The change goes through the existing system call, not a screen mutation.
- **Sales:** offer and contract cards are much more compact, so several fit on screen and drag-to-prioritise across a long list is easy. Keep the essentials (item, qty, payment, due, status) and push detail to a tap.

**Blocked by:** None — can start immediately.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd`, `scenes/components/contract_card.gd`, `systems/rooms.gd`, `systems/contracts.gd` (`reorder`), `docs/ui-vision.md`

**Status:** ready-for-agent

- [ ] Cover-all toggle behaves as above; system function tested
- [ ] Sales cards fit noticeably more per screen (state the before/after count at phone width)
- [ ] Drag reorder still works and auto-scrolls on long lists

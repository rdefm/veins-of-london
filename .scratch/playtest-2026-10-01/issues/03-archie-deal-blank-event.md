# 03 — Bug: Archie deal text → blank, inescapable event screen

**What to build:** When Archie texts about a deal and the player taps "Continue" in the Messages thread, they land on a blank event page with no way to proceed or exit. Diagnose root cause (likely the text's action routes to an event id/kind that doesn't resolve, or a deal flow expecting a modal), fix so Continue opens the correct deal flow, and guarantee any event screen with no resolvable card has an exit.

**Blocked by:** None — can start immediately.

**Relevant files:** `systems/archie_deals.gd`, `systems/events.gd`, `systems/messages.gd`, `scenes/phone_apps/messages_app.gd`, `archie_deal_result_modal.gd`, event screen scene, `scenes/components/contact_cards.gd` (pending-message actions), `systems/phone_nav.gd`.

**Status:** ready-for-agent

- [ ] Root cause written in the commit message
- [ ] Continue from Archie's deal text opens the working deal flow
- [ ] Regression test reproducing the original path
- [ ] Human check: on-device, receive Archie deal text → Continue → can complete/leave

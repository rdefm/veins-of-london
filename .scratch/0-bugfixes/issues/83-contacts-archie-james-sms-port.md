# 83 — Contacts: port Archie/James SMS content into the generic message thread

**What to build:** Archie's and James's conversations currently live in bespoke one-off SMS screens, separate from the generic chat-thread system every other contact uses. Port their existing SMS content and flow into the generic message-thread pipeline (the same underlying state/schema Des/Nadia/Hakim's threads already use), add a "Messages" button to their existing Contacts cards that opens that thread, and retire the bespoke SMS screens. Whatever currently triggers their bespoke SMS events needs to land its content in the generic message state instead of a bespoke screen's own local state. This is independent of and can proceed in parallel with giving Des/Nadia/Hakim their own cards (ticket 82); together they're prerequisites for retiring the top-level Messages tile (ticket 84).

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] All existing Archie SMS content and flow is preserved, now delivered through the generic message thread instead of the bespoke Archie SMS screens.
- [ ] All existing James SMS content and flow is preserved, now delivered through the generic message thread instead of the bespoke James SMS screen.
- [ ] Archie's and James's Contacts cards each get a "Messages" button opening their thread, matching the pattern used for Des/Nadia/Hakim.
- [ ] The bespoke Archie/James SMS screens are deleted, along with whatever bespoke local state they used to track conversation progress.
- [ ] Whatever previously triggered the bespoke SMS events now populates the generic message state instead, preserving trigger conditions/timing.
- [ ] Tests covering Archie/James's SMS content are rewritten against the generic thread model, not left pointing at the deleted screens.

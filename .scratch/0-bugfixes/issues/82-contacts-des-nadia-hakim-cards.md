# 82 — Contacts: add Des/Nadia/Hakim cards with a Messages button

**What to build:** Des, Nadia, and Hakim currently only exist inside the Phone → Messages app's chat-thread UI, with no presence on the Contacts screen at all — unlike Archie and James, who have proper Contacts cards. Give each of Des, Nadia, and Hakim their own Contacts card, mirroring the pattern Archie's and James's cards already use (recruit row, standing/story actions), and add a "Messages" button on each that opens that contact's existing conversation thread (the generic thread UI the Messages app already renders — reused, not rebuilt). This is step one of consolidating messaging onto Contacts as the single hub; it doesn't yet touch Archie/James's bespoke SMS screens or remove the top-level Messages tile.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Des, Nadia, and Hakim each have a Contacts card showing their standing/story actions, matching the Archie/James card pattern.
- [ ] Each of their cards has a "Messages" button that opens their existing conversation thread, showing the same content currently visible via the top-level Messages app.
- [ ] The top-level Messages app and its conversation-list view are untouched and still reachable/working as before (removal is a later ticket).
- [ ] Tests cover the new Contacts cards and their Messages button routing to the correct thread.

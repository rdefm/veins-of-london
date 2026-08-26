# 84 — Contacts: retire the top-level Messages tile, consolidate on Contacts

**What to build:** With every contact (Archie, James, Des, Nadia, Hakim) now reachable via their own Contacts card and a "Messages" button opening their thread (tickets 82, 83), the top-level Phone "Messages" app tile is redundant with Contacts and only a source of inconsistency. Remove the top-level Messages tile and its conversation-list view entirely — the underlying per-contact thread view stays, it's just reached exclusively from Contacts now. Contacts becomes the single hub for talking to any NPC.

**Blocked by:** 82 (Contacts: Des/Nadia/Hakim cards), 83 (Contacts: Archie/James SMS port)

**Status:** ready-for-agent

- [ ] The top-level "Messages" phone tile no longer appears/is reachable.
- [ ] The Messages app's conversation-list view is deleted.
- [ ] Every contact's thread remains fully reachable via their Contacts card's Messages button — no conversation content is lost or orphaned.
- [ ] Any special-casing that treated Archie/James as exceptions to the generic message system (since they no longer are one) is removed, not left dangling.
- [ ] All tests referencing the old two-UI split (Messages app tile, conversation-list view, legacy-contact special-casing) are updated to reflect Contacts as the sole entry point.

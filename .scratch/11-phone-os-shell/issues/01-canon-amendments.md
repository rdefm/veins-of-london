# 01 — Canon amendments

**What to build:** Update the canon docs so they describe the phone-as-OS shell topology (3-slot dock, app grid as home, You tab retired) before any implementation ticket references them. No runtime behavior changes — this is a documentation-only ticket.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `REFERENCE.md` screen roster no longer lists `you`, `bag`, `inventory`; `home` is documented as the phone app grid; the nav bar is documented as a 3-slot dock (Phone · Map · HQ)
- [ ] `M1-LONDON.md`'s interface doctrine is amended: Phone is the OS shell, Map and HQ are apps within it pinned to the dock, rather than three peer places — the addresses/people/bench content split itself is unchanged
- [ ] `M1-LONDON.md`'s You-tab entry is removed; its future content (reputation, affinities, Fieldcraft) is redesignated to the Profile app
- [ ] `M1-LONDON.md`'s "read-only everywhere except..." bag rule is replaced with "full management outside combat/events, read-only plus Use buttons inside them"
- [ ] `REFERENCE.md`'s home-raid trigger wording changes from "next visit to home screen" to "next visit to HQ"
- [ ] No code changes in this ticket

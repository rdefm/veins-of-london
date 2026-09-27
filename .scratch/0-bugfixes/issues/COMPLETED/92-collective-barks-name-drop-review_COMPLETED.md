# 92 — Prose: fix Collective post-sale barks that name-drop without context

**What to build:** `data/collective_barks.json` holds 6 random one-line "barks" each for Des, Nadia, and Hakim, fired after any sale through that contact. Des's line "That'll go to Sandra in Peckham, if you're wondering. She won't know it was you." names an unestablished character with no prior context — confusing this early in the relationship, since the player has no idea who Sandra is or why it matters that she won't know. Human-confirmed scope: review all 18 barks (not just this one) for the same unearned-familiarity/name-drop-without-context problem.

**Where:** `data/collective_barks.json`. Tone reference: `docs/CONTENT-GUIDE.md`.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Review all 18 barks (6 each for `des`, `nadia`, `hakim`) against the same problem class: does the line assume context/relationships/references the player hasn't earned yet at the point it can fire?
- [ ] Rewrite any that have the problem — including the confirmed "Sandra in Peckham" line — so they read clearly without requiring outside context, while keeping each contact's voice consistent with their existing lines.
- [ ] Lines that are fine as-is stay unchanged — this is a targeted fix, not a wholesale rewrite of all 18.
- [ ] Flag the file **PROSE-REVIEW** per `docs/CONTENT-GUIDE.md`'s convention for human audit of new/changed prose.
- [ ] No test changes expected (this is data-only content) unless existing tests assert exact bark text, in which case update them to match.

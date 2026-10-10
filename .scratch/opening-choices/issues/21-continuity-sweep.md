# 21 — Opening continuity sweep

**What to build:** The remaining opening factual and time errors are gone, and the content lint is clean for the whole opening chain:
- Archie's cultivation speech (`archie_cultivation`) uses one model with no garden metaphor: cultivate pushes it up; light prune takes some calc and leaves it growing; hard prune takes more and sets it back; let it go dead and it's gone. Drop "harvest" or define it once as the umbrella word.
- The player's tutorial text to Archie no longer claims the player holds calc.
- Rent deadline matches the bill day (default: Monday per ADR 0006; owner may instead keep "Friday" and move the bill day in data — confirm before applying).
- Any remaining label/time drift ("The next morning… tonight", "half ten on a Tuesday") fixed or tokenised.

Small prose edits go through a short proposal file first, flagged `PROSE-REVIEW:`.

**Blocked by:** 08 — Content lint; 14 — Buyer apply; 20 — Raid apply.

**Relevant files:** `data/events/archie_cultivation.json`, `data/contact_texts.json`, `data/events/intro.json`, `data/events/buyer.json`, `data/constants.json` (bill day, if Friday chosen), `systems/time_system.gd`, `tests/test_event_content_lint.gd`, `docs/CONTENT-GUIDE.md`. Staff cultivate veins, not plants: no soil/clay/digging vocab.

**Status:** ready-for-agent

- [ ] Rent-day choice confirmed with owner.
- [ ] Short proposal approved, then applied.
- [ ] Content lint passes with no opening-chain entries in its known list.

# 06 — Cold open (Nick)

**What to build:** The full Prologue step 1. First, the `add_item` event op gains an optional `tier` (default 1), so an event can grant a T5 Rewind. Then fill the cold-open event, starting from `intro` cards 1–10 (extract and patch, don't rewrite from scratch). Archie hands you a T5 Rewind, one of James's: "If it goes bad, break it." The buyers arrive; the text sets up **Nick**. Combat opens and Nick's **sucker punch is the first beat of round 1** (enemy first, forced crit/KO on Archie). All moves open with one-line coach marks. Below the HP threshold the bar locks to the Rewind with Archie's line as the prompt; the player taps it. After the Rewind: you warn Archie, he guards the sucker punch, throws a Time Pearl (freeze), you leg it. Resume cards close the scene and hand off to the pub.

Nick (`docs/story-restructure.md` "The lieutenant"): low-level Firm, distinctive and memorable, petty, enjoys it slightly too much; written so the player wants revenge. Absent from the rest of the Prologue. No family/mirror backstory. The "early tell" (a call mid-shakedown where his voice changes) is a candidate for this scene: **ask the owner** before placing it here rather than at Hakim's yard (Act 1). Placeholder sprite (reuse an existing enemy sprite). Tune so the fight can't be won and the lock lands within a few rounds.

**Prose rules:** follow `docs/writing-guide.md` (structure, humour, characters, audit) and `docs/CONTENT-GUIDE.md`. Run the writing-guide audit before handing in. Flag every new/changed prose file with `PROSE-REVIEW:`.

**Blocked by:** 05 — Prologue chain skeleton.

**Relevant files:** `systems/events.gd` (`add_item` ~L806), `systems/crafting.gd` (`inventory_add`), `data/events/intro.json` (cards 1–10), the beat 1 placeholder event, `data/enemies.json`, `data/combat_rounds.json` (coach hints), `tests/test_scripted_fight.gd` (script shape). REFERENCE §3.7b "Scripted fights", "Coach marks"; §3.9a. `docs/story-restructure.md` Prologue step 1, Motivation spine. Prose source: `reference/london-orichalchum.html` (prose only).

**Status:** ready-for-agent

- [ ] `add_item` with `tier: 5` grants a T5 Rewind; without `tier` behaves as before; test covers both. REFERENCE updated.
- [ ] Event runs headless: Rewind granted, scripted fight, lock, Rewind, post beats, resume, hand-off to the pub.
- [ ] Nick characterised per the doc; no backstory leaks.
- [ ] Writing-guide audit done; `PROSE-REVIEW:` flagged.
- [ ] Human on-device: sucker punch timing, lock prompt readable, Rewind + freeze feel, pacing.

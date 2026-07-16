# CONTENT GUIDE — prose extraction, patches, and the tone bible

## 1. The two prose channels

**A. Existing tutorial prose — EXTRACT, never rewrite.** The prototype's event text is finished, human-approved writing. Your job is transcription with a short patch list (§2). Any deviation beyond the patch list is an error.

**B. New prose — DRAFT against the tone bible (§3), then flag.** District events, district blurbs, the cultivating tutorial, new notifications and UI copy. Every file containing new prose gets listed under `PROSE-REVIEW:` in your task report. Do not consider new prose final; consider it a draft for the human.

## 2. Extraction map & patch list

Extract card arrays and SMS scripts from `reference/london-orichalchum.html` by their const names (search the file for the name; take the array verbatim, including labels and card types):

| Target event JSON | HTML const |
|---|---|
| intro | INTRO_CARDS |
| buyer | BUYER_CARDS |
| james_meeting | JAMES_CARDS |
| archie_craft_chat | ARCHIE_CRAFT_CHAT_CARDS |
| archie_motion | ARCHIE_MOTION_CARDS |
| james_motion | JAMES_MOTION_CARDS |
| home_raid_intro | HOME_RAID_INTRO_CARDS |
| home_raid_debrief_win | HOME_RAID_WIN_CARDS |
| home_raid_debrief_loss | HOME_RAID_LOSS_CARDS |
| SMS thread 1 | ARCHIE_SMS_1 |
| SMS thread 2 | ARCHIE_SMS_2 |

**DO NOT PORT: `JAMES_CRAFT_CARDS`** (dead, unreachable content — its lesson already lives inside JAMES_CARDS).

Mandatory patches during extraction (ore-roster rename; apply EXACTLY these, nothing else):
1. JAMES_CARDS: `"Motion calc, forty units."` → `"Physics calc, forty units."`
2. JAMES_MOTION_CARDS: `"Motion powder. It's straightforward. Motion orichalchum, compressed differently to the pearls"` → `"Enhancement powder. It's straightforward. Life orichalchum, compressed differently to the pearls"`
3. JAMES_MOTION_CARDS: card label `'New recipe: Motion Powder'` → `'New recipe: Enhancement Powder'`; and in the same card's text, `"you're pushing the calc outward"` stands, but any other instance of "motion" as an ore/recipe name → "enhancement".
4. JAMES_MOTION_CARDS: `"Low-grade powder gives you one extra action in a fight."` — keep as-is (still true).
5. ARCHIE_MOTION_CARDS: no ore names appear; extract verbatim.
6. Strip HTML entities/tags: `<em>…</em>` → plain text (the event card renderer has no rich text in M0); `\u2014` → "—".

## 3. Tone bible (enforced, checkable per line)

The blend: **Benedict Jacka's London narrated with Douglas Adams' dryness — 50/50 menace and comedy.** Each makes the other land harder.

Rules — audit every new line against ALL of these before shipping:
1. **Danger is sincere.** Violence has consequences. Nobody monologues. A threat that can't hurt the player doesn't get written.
2. **Humour is coping, not whimsy.** The narrator jokes the way Londoners joke at a delayed funeral. One dry line per threat — never two, never three.
3. **The joke sits next to something that could hurt you.** If a scene is all jokes, cut jokes. If it's all menace, one dry observation is allowed to breathe.
4. **If a line winks at the camera, it dies.** No fourth wall, no "quirky", no exclamation marks in narration, no whimsical similes. The prototype's register is the target: matter-of-fact, observational, administrative.
5. **The ancient is administrated.** Old secrets are kept via filing systems, livery companies and quiet men with lanyards. Wonder leaks through the mundane; it is never announced.
6. **Magic is stock.** Orichalchum is a trade commodity with VAT implications. Nobody in-world finds it as remarkable as they should.
7. **Litmus test:** if the line would work as an Alex Verus aside or a Fallen London snippet, it ships.

Voices:
- **Archie** — cockney-inflected, blunt, bitingly funny, generous in deed not word. Magic is stock to shift. Time-allergic (canonical; explains the vein he gave away), permanently annoyed about it. Says "calc". Deflects gratitude by leaving.
- **James** — 60s, brilliant, bitter, precise. Helping people is structurally embarrassing. Quotes Plato and the *Critias*, and is on the record *right*, which makes it worse for everyone. Insults are exact, never crude — except one calibrated profanity per scene at most.
- **Narrator** — second person, present tense, dry. Notices administrative details (the coffee cup knocked over; the bin shot Archie doesn't acknowledge).
- **The Conclave** (later) — liveried understatement. The politest frightening people in the game.

Register examples (from the canon prose — imitate this, not generic fantasy):
- "The third one just stands there, which is somehow worse."
- "You're essentially a deterrent. Like a scarecrow. No offence." / "Some offence." / "Noted."
- "He finishes his pint and leaves. You sit with the other one and the chips and the fact that your rent problem has, somehow, become a different problem entirely."

## 4. UI copy rules
Notifications: one sentence, dry, concrete numbers ("Day 4: −£50 living costs."). Button labels: verbs, ≤3 words. Error/blocked states get a reason, not an apology ("Not enough calc." / "No blocks left today."). Never exclamation marks except in a character's dialogue.

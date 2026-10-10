# Vein — event writing guide (TL;DR)

Read this, then the event's outline or current JSON, then write. The reference
example is `intro-proposal2.md` in this folder; when in doubt, copy what it does.

Deeper sources, only when needed:
- Character personality and voice: `docs/CHARACTER-VOICE-GUIDE.md`. Read the section for every character who speaks.
- Full tone bible: `docs/CONTENT-GUIDE.md` §3.
- Canon facts (ore types, allergies, who knows whom): `CONTEXT.md`, `docs/VISION.md`, `docs/REFERENCE.md`. Grep these; don't read them whole.

## 1. What every event must do

1. **Hook on card 1.** Open on concrete, everyday pressure (rent, a debt, a deadline, a place, a time), not on magic or backstory. The first line should make the player want the second.
2. **Set the focus.** Vein is a London economy game: calc is *stock*. Each scene should make the money, the risk, or the trade visible. End on what's next (a payday, a threat, a job), not on a summary of feelings.
3. **Be brief.** Players want to get back to the game. Cut any card the player wouldn't miss. Dialogue gives the player what they need to act, and nothing more.
4. **Be funny twice, never at the threat's expense.** See §3.
5. **Make every named character a person, not a plot device.** See §4.

## 2. Structure and pacing

- **One beat per card**, readable on a phone: aim for 15–45 words, hard ceiling ~60. Alternate action → reaction → dialogue. Let pauses do work: a short card after a big one ("He stops whistling.") lands harder than more words.
- **Cause and effect must be legible.** Why is the player here? What goes wrong? How do they get out? Why do they agree to the next step? If the player could ask "wait, why?", fix it.
- **Show first, explain second.** The strange thing happens on screen, then someone explains it in words a newcomer would use: what it does, what it costs, who buys it.
- **Labels** mark a jump in time or place (`"Fifteen minutes later — a Wetherspoons"`) or a turn in tension (`"It goes wrong"`). Format: `When — Where`, em dash. Most cards have `label: null`.
- **Card types:**
  - `narration`: the narrator.
  - `speaker`: one character. It can open with a short action beat before the quote: `He's whistling... "Two blokes, cash..."`.
  - `tension`: the moment danger arrives.
  - `resolution`: the aftermath or cool-down.
  - `choice`: player decision. Keep the existing `choices[].effects`; you only rewrite `text`, `label` and `result_text`. **Exception, opening events** (intro, buyer, james_meeting, archie_craft_chat, archie_cultivation, home raid intro/debriefs): the beat table in `.scratch/opening-choices/spec.md` "Content" (review §18.4) supersedes this. Add or change choices, option `id`s, `check`/`success`/`fail`, `requires`, `goto` and effects as it specifies (`docs/REFERENCE.md` §3.9a). Reference example: `intro-proposal3.md`.
- **Merge consecutive cards** from the same speaker unless the split is a deliberate pause.
- **Don't duplicate a reveal.** If a character is going to explain something (Archie's allergy), the narrator shows only the symptom ("His eyes are streaming."), not the diagnosis.
- **Handoff:** read the previous and next event in the chain. Names, objects and promises must line up ("I'll text you" → the next event opens on a text).

## 3. Tone and humour

The blend: Benedict Jacka's London, Douglas Adams' dryness, Terry Pratchett's wit, and *The Office*'s practical absurdity and awkward work talk. Half menace, half comedy, and each makes the other land.

- **Danger is sincere.** Knives cut. Nobody monologues. Never undercut a threat in the card that delivers it.
- **Humour budget per scene:** two anchor jokes, plus small in-character deadpan. Every joke is one line, and no beat gets two jokes. If a scene starts to feel like a sketch, cut jokes.
- **Where jokes go:** next to danger, not on top of it. Before a threat, after an escape, or as coping. Good: "Somewhere with lights. And witnesses." Bad: a gag in the same card as the knife.
- **Humour comes from coping and from being ordinary.** Job interviewers keeping your details on file. Magic with expenses. Never whimsy, never quirky, never a wink at the player.
- **Pop-culture references:** at most one per scene, in dialogue only, British, and something that character would say. Never in narration.
- **Narrator:** second person, present tense, dry, observational. Notices practical, admin-type details (a Tesco bag, a grey Vauxhall, which way someone sits). No exclamation marks. Never tells the player how to feel. At most one simile per scene, and it must be concrete ("like a video buffering"), not ornate.
- **Magic is stock.** Nobody in-world is as amazed as they should be. Calc is sourced, processed, sold and marked up. Say "calc"; "orichalchum" only when explaining, or when someone is being posh.

## 4. Characters as people

Before writing, give each speaking character, from their CHARACTER-VOICE-GUIDE entry:
- **A habit or tell** visible on screen (whistling, then stopping when it goes wrong).
- **An act of care, done not said**, ideally one that costs them something. Archie steps between you and the knife, uses his last pearl, buys the chips. Nobody comments on it.
- **A want of their own**, separate from what the plot needs from them ("I need someone with me").
- **A canon trait shown, not explained.** Archie's time allergy appears as streaming eyes plus "Don't.", not as a lore paragraph.
- **Minimal exposition, in their voice.** No exposition disguised as dialogue: characters never tell each other things they both know. When someone has to explain, give only what the player needs now, wrapped in a dig, a sales pitch or a complaint.
- **Distinct speakers.** Cover the names: you should still know who's talking. Not everyone is sardonic; the narrator's dryness isn't everyone's voice.
- **Honesty with the player.** Allies tell you the odds and let you say no. It makes them trustworthy, and it makes the player's choice theirs.
- **A characteristic exit.** Archie leaves before you can thank him.

**Dialect** comes from vocabulary and rhythm, never phonetic spelling. Archie: "lads", "leg it", "ain't I", "and all", "lovely", one "innit" per scene. Never "nuffink" or dropped-h apostrophes. The same rule applies to Des, Nadia and every other accent.

**The player ("You")** speaks rarely and sensibly: asks the question a real person would ask, notices risk, and agrees for a concrete reason ("You look at the door, at the chips, then think about your bank balance."). The player can be teased and can push back lightly. They're never a punchline.

## 5. Vocabulary and canon guardrails

- The ore types are `time`, `physics`, `life`, `fate`, `emotion`, and nothing else. Currency is `£`, whole pounds.
- Staff cultivate veins. Never use gardening words (soil, clay, digging, planting) for that work.
- Don't invent mechanics, prices or numbers in prose that contradict `docs/REFERENCE.md`. If prose needs a figure, grep for it first or leave it vague.
- Keep `id`, `on_complete`, choice `effects` and image paths and order exactly as they are (opening events: see the §2 `choice` exception). Moving an image to a different card is allowed, but call it out. Convention art (`<id>_card<N>`) follows card *index*, so when cards are added or removed, pin shifted art with explicit `image` keys.
- Preserve canonical names: characters, places, factions, items and ore types exactly as `CONTEXT.md` / `docs/REFERENCE.md` and the existing events spell them. Don't rename or add nicknames without flagging it.
- `reference/london-orichalchum.html` (the old prototype) is a source of prose only. Never take mechanics, numbers or data from it.

## 6. Deliverable

A Markdown file in `.scratch/writing-revamp/` named `<event-id>-proposal.md`, containing:
1. **Title + short intent note:** how the draft meets each of the five goals in §1, in one or two lines each.
2. **One complete, valid ```json block** in the event's existing schema. Check that it parses.
3. A line confirming `id` / `on_complete` / images are unchanged, or listing exactly what changed.
4. **Open points for review:** lines you're unsure about (a possible third joke, a canon stretch, an alternative ending).

The owner reviews proposals in `tools/storyboard.html` (picker → "Proposals"), which reads the first ```json block, so keep exactly one complete event block per file. Never edit `data/events/*.json` until the human asks you to apply a proposal. When asked to suggest changes, post them in chat as **Now / Proposed / Why** per card, and don't touch the file. Flag new prose in your report as `PROSE-REVIEW: <path>`.

## 7. Final audit (tick every line before delivering)

- [ ] Card 1 hooks on concrete pressure; last card points at what's next.
- [ ] Every card is one beat and ≤ ~60 words; no card the player would miss; no back-to-back same-speaker cards without a reason.
- [ ] Exactly two anchor jokes, each beside danger, never on the threat card; the scene doesn't read like a sketch.
- [ ] The threat card is played straight and the danger is real.
- [ ] Each speaking character has a tell, an unspoken act of care, a want, and their CHARACTER-VOICE-GUIDE voice; speakers are distinguishable with names covered; no exposition disguised as dialogue.
- [ ] No reveal is shown twice (narrator and dialogue).
- [ ] Dialect comes only from words and rhythm; at most one pop-culture reference; at most one simile; no exclamation marks in narration.
- [ ] The magic is shown before it's explained, and explained as stock.
- [ ] Canon and vocabulary checked (canonical names, ore types, "calc", £, allergies, no gardening words); handoff to the adjacent events is consistent.
- [ ] JSON parses; `id`, `on_complete`, effects and images preserved.

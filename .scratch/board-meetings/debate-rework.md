# Board meeting rework — "the debate"

**Status:** DRAFT for human approval. Not decided, no tickets yet. Supersedes the "Running order" step 2 (Agenda) in `docs/biz-meetings-vision.md` if approved.

## Problem
Agenda = one text dump per goal (name, quote, "Why now:", tiers, "Pays:") then a choice. Reads as a form, not people.

## Intent
James, Archie, Owen argue what the business needs this week. Each wants it to succeed; they disagree on the lever. Player casts the deciding vote.

| Voice | Wants | Argues for | Sounds like |
|---|---|---|---|
| James | Prove the firm (and himself) better than the Guild | Craft quality, recipes, rank | Exact, grudging, Guild as the yardstick |
| Archie | Enough cash to stop fearing bills, and spare to help people | Sales, share, deals, reserve | Quick, blunt, money as safety |
| Owen | Not to get it wrong; stay on what he knows | More yield, more veins, a new ore | Hesitant, apologises, retreats to veins |

Owen's default: when he isn't pitching and is asked to weigh in, he drifts to veins ("could the veins come into it?"). He pitches rarely (pitchRarity 0.25 unchanged).

## Shape of the scene (N = offered goals, 1-3)
1. **Minutes** — unchanged (existing reaction lines).
2. **Opener** — one seeded line, the voice with the pitch-order-first card frames "what the business needs".
3. **Per goal, in seeded order:**
   - **Case** (pitcher): the argument. Carries the true premise (old `why`) inside the voice; replaces `pitch` + `why`. Max ~45 words.
   - **Response** (one of the other two, seeded): `back`, `challenge`, or `wobble` (Owen's stance). Short; may name the other lever ("and who's selling it?").
   - **Rebuttal** (optional, pitcher, only after a `challenge`): one line, may concede.
4. **Clash** (optional, once, ~50%): a two-line exchange between the two voices with the most opposed levers in this agenda. Keyed by voice pair.
5. **Vote** — "Over to you." Prompt card holds the compact numbers ("Base/Target/Stretch · Pays"), option labels = plain goal names (+ pitcher name).
6. **Result** — pitcher pleased in a line; one other concedes in a line. Unpicked voices stay warm (no coolness, per vision).
7. **AOB** — unchanged.

Skip ("Leave it to Archie") stays on the vote card.

## Data layout (board.json)
- `templates[id]`: `label` (kept), `case[]` (new, replaces `pitch[]`+`why[]`), tokens as today ({calc}, {share}, {rival}, {expenses}...).
- `meeting.debate`:
  - `opener[voice][]`
  - `response[responder][pitcher][stance][]` — generic, tokens {label}, {ore}. Reused by every future ladder, so tickets 16-26 only write `case`.
  - `rebuttal[pitcher][]`
  - `clash["james|archie"|"archie|owen"|"james|owen"][]` — each entry a 2-card pair.
  - `votePrompt`, `chosen[pitcher][]`, `concede[voice][]`
- Removed: `agendaCard`, `agendaSeparator`; `tierFormat`/`rewardFormat` move to the vote prompt.

## Code/engine impact
- `meeting_context()` builds `c<i>_case`, `c<i>_response_*` etc. into context; deterministic via `_seeded_index` (Rewind-safe).
- `board_meeting.json` / `board_meeting_week1.json` skeleton becomes a fixed 3-slot run. **Open:** <3 goals need slots skipped. Options: (a) `if` entries in card `goto` on a new `context_flag` condition; (b) generate the event's card list in context. (a) is smaller. Needs your OK.
- GameData lint + `test_board_meetings.gd` updated (template shape, token presence, no unfilled `{}`).
- CODEMAP row for `board.json` / `board_meetings.gd` updated.

## Decisions (approved by human)
1. **Ladder ownership.** `fin_reserve` moves James -> Archie. James also pitches `share_leader` as Guild-beating (alt template).
2. **Guild as James's yardstick.** Rival *standard* only, never a live-state claim.
3. **Week-1 meeting:** keep explainer + Owen-poach gag, then run the same debate.
4. **<3 goals:** skip empty slots via new `context_flag` condition in card `goto`.

## Prose principles (for every ticket)
1. **A case states the goal outright**: the concrete target, in the pitcher's words ("25% of London's time calc", "sell £x this week"), then why it helps the business. A reader must be able to say what is being proposed.
2. **Justification follows the voice's motive** (table above), and is a real business reason, not a flourish.
3. **Replies answer what was just said.** A response or rebuttal picks up a specific claim in the previous card. No lines that float free of it.
4. **People say the numbers.** No "I wrote it down" coyness; Owen's hesitancy is in hedging and apology, not withholding.
5. **No oblique images.** If a line needs a second read to find its meaning, rewrite it. Jokes are plain observations, not riddles.
6. Premise figures are tokens ({share}, {expenses}...), never typed.

## Worked sample (rewritten)
Agenda: Archie `share_first` (time calc), James `craft_first` (time calc), Owen `cult_yield`.

*Minutes line as today.*

**Archie** (case): "I want us at 25% of London's time calc this week. We're on 18%. While we're small, any firm that cuts its price drags ours down with it. Get big enough and we're the ones moving the price. That's when bills stop being scary."

**James** (challenge): "A bigger share of poor work is still poor work, and I'll not be selling it. You've picked the wrong thing to be big at, Archie."

**Archie** (rebuttal): "Buyers look at price before they look at craft, James. Get the share first, then be as fussy as you like."

**James** (case): "I'd rather we craft 30% of the time calc made in London. We're on 14%. The Guild still sets the standard for what a good piece looks like. The more of it we make, the more buyers will put ours next to theirs. I'm not worried about that comparison."

**Archie** (back): "Fair, if it sells. Better work means we can ask more for it, and I like asking more."

**Owen** (case): "Sorry. Can I suggest something? Could we beat our usual ten-day yield this week? Just over it, not a lot. More coming out of the veins means more to sell and more to craft, so it helps what both of you want. And I know how to do it."

**James** (back): "That is sensible. You can't craft with nothing on the bench. Carry on, Owen."

**Archie** (to you): "Over to you. We all want the firm to do well. We just want different things first."

> **Vote:** `Archie: A bigger corner of time calc` / `James: Craft more time calc` / `Owen: A bit more yield`
> Prompt card: "Base 20% / Target 25% / Stretch 30% · Pays £100 / £250 + pearl / £400 + pearl + powder" (shown per option)
> **Chosen (Archie):** "Good. Twenty-five percent. I'll tell the bank. Actually, I won't."
> **Concede (James):** "Very well. I'll make sure what we sell is worth the price."

Notes: each pitch names the target and a real business reason; every reply refers to something just said; Owen states his ask plainly and hedges only in manner.

## Plan if approved
1. Tickets (one per beat, each cites `docs/writing-guide.md` + `CHARACTER-VOICE-GUIDE.md`): skeleton + engine slot-skipping; debate data + generic response/clash/rebuttal prose; rewrite 12 existing `case` lines; week-1 intro adjust; update 16/18/20/22/24/26 to write `case` only.
2. All new prose flagged `PROSE-REVIEW:`.

# Buyer event — proposal (choices)

Rewrite of current `data/events/buyer.json` adding the two buyer beats from review §18.4 / spec "opening-choices" ticket 13. Builds on `intro-proposal3.md` (option ids `stand` / `askBuyers` / `wantHalf` on intro card 3; flags `introAskedQuestions`, `introBrave`, `introWantsHalf`).

**Card count:** 10 definition cards (was 12). The player sees **10** (was 12): 7 spine cards, the Marcus resolution, one of three split cards, and its resolution. Saved by: cutting the "texts an address" opener (the SMS already did it), the "Some offence." / "Noted." exchange (review tic list), the "Sure" card, and merging the Marcus narration into the Marcus choice.

Goals:

1. **Hook + focus.** Card 0 opens on Archie holding the calc outside a bar. The Marcus card is the first trade the player makes: one price, three ways to take it, one roll.
2. **Brevity.** The split costs nothing on top: three split cards exist in data, the player sees one. Every path rejoins at card 8.
3. **Humour beside danger.** Anchors: "Like a scarecrow" (before the sale, against the knife memory) and "Professional, prompt, no Stanley knife" (after). The duke story and "a look that costs more" are one-path deadpan.
4. **Archie as a person.** Tell: a hand on his inside pocket the whole time. Care: he pays the 60/40 he resented, slowly, so you watch. Want: buyers who don't bring knives. Exit: already texting James before you answer (no "before you can thank him", review tic).
5. **Continuity.** Runs at Evening (`at: evening, advance: true`), so "tonight", the night art and the board agree; card 0 label `{today} — Shoreditch` resolves to "Tonight — Shoreditch". Art shows a cocktail bar, so the text says cocktail bar. Archie holds the calc, so the lead-in SMS no longer has the player selling it. The James SMS drops "Tomorrow … Midday" (nothing delays the pending message, so the player can tap it at once) and matches james_meeting's "beside a halal supermarket".

## Beats → options

| Card | Option id | Label | Mechanics | Cash (even / 60-40) |
|---|---|---|---|---|
| 4 Marcus | `takeIt` | Take the £80 | none → split card 5 | £40 / £48 |
| | `pushMore` | Push for more | check 40%, +15% `introAskedQuestions` "You asked who buys this stuff", +10% `introBrave` "You stood in front of a knife", `show: odds`. Success → card 6 (£120). Fail: Archie −3 → card 7 (£60) | £60 / £72 · £30 / £36 |
| | `archieTalks` | Let Archie talk | Archie +3 → split card 5 | £40 / £48 |
| 5–7 split | `split` / `splitAsked` / `splitHalf` | Pocket £N | gated by intro card 3 memory: `stand` / `askBuyers` / `wantHalf` (`display: hide`); grants the player's cut; 5 and 6 `goto` 8 | as above |

Push odds: 40% base, 55% with the cousin question, 50% brave, 65% both. Expected cash (even split): 40% → £42, 65% → £50, vs £40 for Take. Pushing is the better bet only once the intro choices back you, which is the payoff.

The cash is granted on the split card only. `on_complete` no longer adds £40.

```json
{
  "id": "buyer",
  "at": {
    "block": "evening",
    "advance": true
  },
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "buyerEventSeen",
      "value": true
    },
    {
      "op": "set_stage",
      "value": "sms_archie"
    },
    {
      "op": "push_message",
      "contact": "archie",
      "text": "James says yes. SE1 4YA, storage unit beside the halal supermarket. He's always in."
    },
    {
      "op": "queue_pending_message",
      "contact": "archie",
      "kind": "james_meeting",
      "text": "Fair warning: James is the best craftsman I know and also the worst person I know. Don't take it personally. He's like that with everyone."
    },
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "{today} — Shoreditch",
          "speaker": null,
          "text": "Archie is outside a cocktail bar, looking at it the way you'd look at a parking fine. One hand stays on his inside pocket.",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Buyer's inside. Marcus. Finance. Wants one chip of emotion-type, for his mood, apparently. Don't ask. Just be normal.\"",
          "key": "c2"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"That's the calc they pulled a knife over.\"",
          "key": "c3"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Correct. Which is why there's two of us. You're a deterrent. Like a scarecrow.\" He considers you. \"No offence.\"",
          "key": "c4"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": "Marcus",
          "text": "Fleece, Patagonia, very clean trainers. Marcus turns the chip over with the careful enthusiasm of someone who has recently read about it online. He puts it down. \"Eighty.\"",
          "image": "res://assets/events/buyer/buyer_card7.jpg",
          "choices": [
            {
              "id": "takeIt",
              "label": "Take the £80",
              "effects": [],
              "result_text": "You nod. Marcus counts out four twenties and slides them across. Archie pockets them before Marcus can change his mind."
            },
            {
              "id": "pushMore",
              "label": "Push for more",
              "check": {
                "base": 0.4,
                "mods": [
                  {
                    "flag": "introAskedQuestions",
                    "add": 0.15,
                    "label": "You asked who buys this stuff"
                  },
                  {
                    "flag": "introBrave",
                    "add": 0.1,
                    "label": "You stood in front of a knife"
                  }
                ],
                "show": "odds"
              },
              "success": {
                "result_text": "\"It's emotion-type. Nobody's selling it this side of the river.\" Marcus looks at the chip, then at Archie, who says nothing at all. \"A hundred and twenty.\" He pays it.",
                "effects": [],
                "goto": {
                  "branch": "b7"
                }
              },
              "fail": {
                "result_text": "Marcus's face closes. \"Sixty. Or I've got a guy in Hackney.\" Archie takes the sixty, and gives you a look that costs more.",
                "effects": [
                  {
                    "op": "relation",
                    "contact": "archie",
                    "value": -3
                  }
                ],
                "goto": {
                  "branch": "b8"
                }
              }
            },
            {
              "id": "archieTalks",
              "label": "Let Archie talk",
              "effects": [
                {
                  "op": "relation",
                  "contact": "archie",
                  "value": 3
                }
              ],
              "result_text": "Archie talks. Provenance, rarity, a duke you're fairly sure he's made up. Marcus pays eighty and looks pleased to."
            }
          ],
          "key": "c5"
        },
        {
          "type": "choice",
          "label": "Walking back — Shoreditch High Street",
          "speaker": null,
          "text": "Archie splits the eighty on the pavement outside a Pret. The city walks round you both.",
          "image": "res://assets/events/buyer/buyer_card9.jpg",
          "choices": [
            {
              "id": "split",
              "label": "Pocket £40",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "stand"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 40
                }
              ],
              "result_text": "Two twenties. Rent's still due Monday, but it's closer.",
              "goto": {
                "branch": "b9"
              }
            },
            {
              "id": "splitAsked",
              "label": "Pocket £40",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "askBuyers"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 40
                }
              ],
              "result_text": "Two twenties. Rent's still due Monday, but it's closer.",
              "goto": {
                "branch": "b9"
              }
            },
            {
              "id": "splitHalf",
              "label": "Pocket £48",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "wantHalf"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 48
                }
              ],
              "result_text": "He counts out forty-eight, slowly, so you can watch him do it. \"Sixty-forty. Your way. As agreed.\"",
              "goto": {
                "branch": "b9"
              }
            }
          ],
          "key": "c6"
        }
      ],
      "then": {
        "branch": "b7"
      }
    },
    "b7": {
      "title": "Walking back — Shoreditch High Street",
      "cards": [
        {
          "type": "choice",
          "label": "Walking back — Shoreditch High Street",
          "speaker": null,
          "text": "Archie splits the hundred and twenty on the pavement outside a Pret. The city walks round you both.",
          "image": "res://assets/events/buyer/buyer_card9.jpg",
          "choices": [
            {
              "id": "split",
              "label": "Pocket £60",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "stand"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 60
                }
              ],
              "result_text": "Three twenties. Rent's still due Monday, but it's closer.",
              "goto": {
                "branch": "b9"
              }
            },
            {
              "id": "splitAsked",
              "label": "Pocket £60",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "askBuyers"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 60
                }
              ],
              "result_text": "Three twenties. Rent's still due Monday, but it's closer.",
              "goto": {
                "branch": "b9"
              }
            },
            {
              "id": "splitHalf",
              "label": "Pocket £72",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "wantHalf"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 72
                }
              ],
              "result_text": "He counts out seventy-two, slowly, so you can watch him do it. \"Sixty-forty. Your way. As agreed.\"",
              "goto": {
                "branch": "b9"
              }
            }
          ],
          "key": "c7"
        }
      ],
      "then": {
        "branch": "b8"
      }
    },
    "b8": {
      "title": "Walking back — Shoreditch High Street",
      "cards": [
        {
          "type": "choice",
          "label": "Walking back — Shoreditch High Street",
          "speaker": null,
          "text": "Archie splits the cash on the pavement outside a Pret. The city walks round you both.",
          "image": "res://assets/events/buyer/buyer_card9.jpg",
          "choices": [
            {
              "id": "split",
              "label": "Pocket £30",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "stand"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 30
                }
              ],
              "result_text": "A twenty and a ten. Rent's still due Monday."
            },
            {
              "id": "splitAsked",
              "label": "Pocket £30",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "askBuyers"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 30
                }
              ],
              "result_text": "A twenty and a ten. Rent's still due Monday."
            },
            {
              "id": "splitHalf",
              "label": "Pocket £36",
              "requires": {
                "choice": {
                  "event": "intro",
                  "card": 3,
                  "option": "wantHalf"
                }
              },
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": 36
                }
              ],
              "result_text": "He counts out thirty-six, slowly, so you can watch him do it. \"Sixty-forty. Your way. Of sixty.\""
            }
          ],
          "key": "c8"
        }
      ],
      "then": {
        "branch": "b9"
      }
    },
    "b9": {
      "title": "From card 9",
      "cards": [
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"See? Professional, prompt, no Stanley knife. Most of them are like Marcus. That's the market we're after.\"",
          "key": "c9"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Next thing. Bloke called James, Bermondsey. Takes raw calc and makes it do things, like that thing I threw in the alley. I'll set it up.\" He's texting before you've answered.",
          "key": "c10"
        }
      ]
    }
  }
}
```

## Lead-in texts (`systems/time_system.gd` `_apply_tutorial_day_triggers`)

The day-2 trigger currently has the player offering calc to sell ("Got some calc to move. You got a buyer?" / "Mixed. Maybe fifteen units."), but Archie holds the bag. Proposed thread, same four calls:

| From | Now | Proposed |
|---|---|---|
| archie | — (player) "Got some calc to move. You got a buyer?" | "Found someone for the calc from the other night. Not in an alley." |
| player | — (Archie) "Yeah give me a day or two. What type and how much?" | "Any knives?" |
| archie | — (player) "Mixed. Maybe fifteen units." | "Finance bloke. Worst he'll do is tell you about his pension." |
| archie (pending `buyer`) | "Sorted. I'll bell you…" + "Actually — you free tonight? … Shoreditch. Easy job." | "Shoreditch, tonight. You in?" |

So the thread is 3 appended lines + the pending one (the "Sorted. I'll bell you" line goes).

## What changed vs. current `buyer.json`

- `id` unchanged. **New `at`:** `{ "block": "evening", "advance": true }`.
- **`on_complete`:** `add player.cash 40` removed (cash now comes from the split card, £30–£72). The player's "When can we sort that?" SMS removed (Archie already said he'd set it up). Archie's SMS reworded: no "Tomorrow … Midday", "behind the Costcutter" → "beside the halal supermarket" (matches james_meeting card 0). Flags, stage, pending message and screen unchanged.
- **Images.** Convention art maps card index N to `buyer_card<N+1>`. `buyer_card1` (night street) stays on card 0 by convention. `buyer_card7` (Marcus) moves from old card 6 to the Marcus choice, card 4, by explicit key. `buyer_card9` (Pret) moves from old card 8 to the three split cards, 5–7, by explicit key. Card 8 (convention `buyer_card9`) would also pick up the Pret art; card 9 (`buyer_card10`, none) inherits it. Both are right.
- **Label lint.** Clears the known violation "buyer: card 0 label 'The next morning' says 'morning' but the event has no at"; ticket 14 removes it from the test's list.
- **Cut cards.** "Archie texts an address…" (narration), "Some offence." / "Noted." (You / Archie), Marcus narration (merged into the choice), "Archie splits the cash" resolution (became the split cards), "Sure." (You).

## Cards needing new art (→ event-storyboard)

None needed to ship; every card has art by key, convention or fallback. Candidates:

1. Card 0's bar sign reads "Shoreditch Spirits Cocktails", which the text now matches. No change.
2. `pushMore` success / fail resolution (optional): Marcus paying up vs Marcus's face closing.
3. `archieTalks` resolution (optional): Archie mid-pitch, hands going.

## Open points for review

- **Split mechanics: three options per split card.** The engine's `requires` has no "not", so "didn't ask for half" is spelled as two gated options (`stand`, `askBuyers`) with identical text. It's valid today. Two weaknesses: data duplication, and a save that reaches buyer with no intro choice memory (e.g. a pre-ticket-12 save or any debug path that skips the intro) hides every option and soft-locks the card. **Recommended alternative:** a one-line engine extension, `requires: { "not": { "flag": "introWantsHalf" } }` (REFERENCE §3.9a vocabulary + lint), which cuts each split card to two options and, keyed off the flag, can't lock. Ticket 14 needs your call.
- **Order dependency.** The split gates and push mods name intro option ids and flags that only exist once ticket 12 applies `intro-proposal3.md`; the content lint fails on this file until then.
- **Three split cards.** Needed because the sale total (£80 / £120 / £60) and the split are independent and `requires` takes one condition. The player never sees more than one.
- **Push numbers.** £120 on success, £60 and Archie −3 on fail. Not in the beat table; taken from review §18.2's example (player cut 60 / 30). Emotion `basePrice` is 81, so £80 is fair, £120 is 1.5×.
- **What's in the bag.** Intro's `howMuch` implies ten chips (~£750). Here Marcus buys one emotion-type chip, the rest unaccounted for. Proposed lead-in drops "Mixed. Maybe fifteen units." to stop adding numbers. A later Archie line could say where the rest went; left out to stay brief.
- **"For his mood, apparently."** Replaces "recreational use" (review tic: Marcus and the City suit both say it).
- **Humour count.** Two anchors + "No offence." + one-path lines (duke, "a look that costs more", "Of sixty."). "No offence." could go if it reads as a third joke.
- **Lead-in SMS lives in code** (`time_system.gd`), not `data/`. Rewording it keeps it there; moving it to data is outside this ticket.
- **James timing.** Data-only fix: the SMS stops promising a day. Ticket 15 should change james_meeting card 0 to `{today} — Bermondsey` (no `at`), clearing its "Two days later" lint entry. A real "tomorrow, midday" needs a day-delayed pending message (code in `_apply_tutorial_day_triggers`); say if you want that instead.

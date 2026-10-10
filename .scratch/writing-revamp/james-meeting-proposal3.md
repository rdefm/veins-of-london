# James meeting — proposal 3 (choices)

Revision of pending `james-meeting-proposal2.md`, adding the two James beats from review §18.4 / spec "opening-choices" ticket 15. Under the spec's beat table, which supersedes "keep existing `choices[].effects`" for opening events (see writing-guide note). Proposal 2's prose is kept unless a beat needed it changed; its own open points are carried at the end.

**Card count:** 22 definition cards (current `james_meeting.json`: 24; proposal 2: 24). The player sees **24** on the normal path (21 cards + 3 result cards) and **26** if they ask James to watch (22 cards + 4 result cards). Saved by: merging "I've never made one" into James's explainer, merging "It isn't really a question" into the Poundland card, making the craft card the pace choice, and making James's payment line the closing choice (its result replaces the old final card).

Goals:

1. **Hook + focus.** Same opening (Archie out of pearls, checking the street). The bench choice is about yield: slow and sure vs more spheres and more losses. The pearls you make are what you leave with. They replace the flat "two good pearls".
2. **Brevity.** Two choices, net −2 cards. The tell/hide branch costs no cards: Tell's reveal is its result card, and Hide's callback lives in the closing card.
3. **Humour beside danger.** Anchors unchanged: "I'm the only craftsman you know" and Critias/Poundland. The one profanity is kept. Per-path lines are deadpan, and a player sees one result per choice.
4. **James as a person.** The jar choice now happens with Archie gone, so James can actually answer. Tell gets more of him (rarity, a warning, a line in the ledger). Say nothing: he notices anyway and says so on the way out. "Ask James to watch" lets him help while refusing to look like he's helping. A 0-pearl session gets one of *his* pearls, which is unasked care.
5. **Continuity.** Card 0 is `{today} — Bermondsey` with no `at`, as the buyer proposal asked; this clears the "Two days later" lint entry. The location is "beside the halal supermarket", matching the buyer proposal's SMS. Last card ends on "Archie will want to know how it went", which sets up `archie_craft_chat`'s pending "how'd it go with James?".

## Beats → options

| Card | Option id | Label | Mechanics |
|---|---|---|---|
| 14 jar | `tell` | "It's doing it again." | James +5, `toldJamesJar`. No odds change; result is James's extra reveal |
| | `sayNothing` | Say nothing | `hidJar`. James notices; closing card 21 says so |
| 18 bench | `patient` | Take your time | 2 attempts × 55%, +1 Time Pearl per success, → card 20 |
| | `rush` | Rush it | 4 attempts × 30%, +1 Time Pearl per success, → card 20 |
| | `askWatch` | Ask James to watch | check 50%. Success: `jamesWatching`, James +3. Fail: James sighs, nothing lost. Either way → card 19 |
| 19 bench, after asking | `patient` / `rush` | as card 18 | same, plus `{flag: jamesWatching, add: 0.10, label: "James is watching"}` → 65% / 40% |
| 21 exit | `leaveTold` | Leave | `requires {flag: toldJamesJar}` (hidden otherwise) |
| | `leaveHid` | Leave | `requires {flag: hidJar}`: James's callback line |

All checks use `show: "odds"`, `min: 0.15`. Card 19 is reachable only from `askWatch` (card 18's `patient`/`rush` outcomes `goto: 20`).

**Outcomes per pearl count** (each check's `fail` is the 0 result; `success` holds the top count; `bySuccesses` holds the counts between):

| Pearls | Take your time | Rush it | Odds, unwatched (slow / rush) | Odds, watched (slow / rush) |
|---|---|---|---|---|
| 0 | `fail` → James's floor pearl | `fail` → James's floor pearl | 20% / 24% | 12% / 13% |
| 1 | `bySuccesses.1` | `bySuccesses.1` | 50% / 41% | 45% / 35% |
| 2 | `success` | `bySuccesses.2` | 30% / 26% | 42% / 35% |
| 3 | n/a | `bySuccesses.3` | n/a / 8% | n/a / 15% |
| 4 | n/a | `success` | n/a / 1% | n/a / 3% |

Expected pearls: slow 1.1 (watched 1.3), rush 1.2 (watched 1.6). Rush has the higher ceiling and the higher bust rate.

## Pacing: 0 pearls

**Proposed: floor of 1.** Unfloored, roughly one player in five leaves with 0 pearls. That empties the later "Show him a pearl" option in `archie_craft_chat` (needs ≥ 1), removes the Time Pearl ambush mod in the home raid (needs one equipped), and breaks the spec's "tutorial failures mild, never blocking". So both `fail` outcomes add one pearl from James's own tray (`add_item timePearl 1`), and the text makes clear it's his, not yours. The 0 result still reads as a failure, but the raid payoff survives. If you'd rather keep a true 0, drop that effect from both `fail` outcomes; the prose survives with one sentence cut.

```json
{
  "id": "james_meeting",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "metJames",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "craftingUnlocked",
      "value": true
    },
    {
      "op": "add",
      "path": "contacts.james.unlocked",
      "value": true
    },
    {
      "op": "relation",
      "contact": "james",
      "value": 10
    },
    {
      "op": "set_stage",
      "value": "archie_craft_chat"
    },
    {
      "op": "queue_pending_message",
      "contact": "archie",
      "kind": "archie_craft_chat",
      "text": "Oi — how'd it go with James? Come find me."
    },
    {
      "op": "add",
      "path": "world.archieChatUnlockDay",
      "value": 1
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
          "label": "{today} — Bermondsey",
          "speaker": null,
          "text": "The storage unit 2 doors down from the halal supermarket. Archie is already there, which has never happened before. He used his last pearl in Whitechapel, and since then he checks the street every time a car slows.",
          "key": "c1",
          "image": "res://assets/events/james_meeting/james_meeting_main_2.png"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"James makes pearls. I need pearls. Next time someone gets a knife out, I'd like more than a carrier bag to wave at them. So be polite, touch nothing, and let me do the talking.\"",
          "key": "c2"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "The door opens. James is in his sixties: glasses with one bent arm, a waistcoat with the slightest stain on it. He looks at Archie, then at you, like a parcel left on the wrong doorstep.",
          "key": "c3"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"You're early. That's new. Come in. Touch nothing.\"",
          "key": "c4"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Shelves of jars run to the ceiling, each labelled in biro. It smells of copper and bleach. Archie stays by the shutter and rubs his eyes.",
          "key": "c5"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You pass a jar marked TIME. The calc inside shifts. It moves to the side of the glass nearest your hand, as if it noticed you.",
          "key": "c6"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "You glance up. James is watching you. His expression doesn't change, exactly. But something in it does.",
          "key": "c7"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"James is the best craftsman I know. That pearl in Whitechapel was one of his.\"",
          "key": "c8"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I'm the only craftsman you know. There's a difference.\" He turns to Archie. \"Forty units of life calc, collected from Stratford within the hour. Do it and your next batch of pearls is at cost.\"",
          "key": "c9"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Who's the seller? Anyone I need to worry about?\"",
          "key": "c10"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Nobody who's ever shortchanged me. The address will be on your phone by the time you reach the station.\" He doesn't look at you. \"I need your friend's assistance with something in the meantime.\"",
          "key": "c11"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "He looks at you, not James. \"Your call. Stay here, or come to Stratford and carry a bag.\"",
          "key": "c12"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "You think about the pearl that stopped the knife, and about rent. \"I'll stay.\"",
          "key": "c13"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Lovely. Ring me if he's more horrible than usual.\" He's gone before James can answer.",
          "key": "c14"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": "James",
          "text": "He takes down the jar marked TIME and sets it on the bench. \"My assistant is indisposed and I have an order for time pearls. You'll do. Gloves.\" Inside the jar, the calc drifts to the side nearest you again. James is looking at the jar, not at you.",
          "choices": [
            {
              "id": "tell",
              "label": "\"It's doing it again.\"",
              "effects": [
                {
                  "op": "relation",
                  "contact": "james",
                  "value": 5
                },
                {
                  "op": "set_flag",
                  "flag": "toldJamesJar",
                  "value": true
                }
              ],
              "result_text": "\"Yes. It did it when you walked in.\" He writes something in the ledger. \"Calc does that for perhaps one person in a few thousand. I have met two.\" A pause. \"Don't mention it to anyone who sells the stuff. They'll want to weigh you.\""
            },
            {
              "id": "sayNothing",
              "label": "Say nothing",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "hidJar",
                  "value": true
                }
              ],
              "result_text": "You say nothing. James says nothing either. He moves the jar six inches to the left, out of your reach, and writes something in the ledger."
            }
          ],
          "key": "c15"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"I assume you've never made one.\" You haven't. \"Then I'll explain it once. A pearl that seals is worth a hundred and twenty pounds to someone frightened. A pearl that doesn't is my calc on the floor. Do try not to fuck it up.\"",
          "key": "c16"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "He measures out the calc. \"Plato wrote about orichalchum in the Critias. Second only to gold, in Atlantis.\" He glances at you. \"You have no idea what the Critias is, do you.\"",
          "key": "c17"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "You don't answer. \"Two and a half thousand years ago, people knew exactly what this was worth. Today Archie is collecting it outside a Poundland in Stratford. Make of that what you will about humanity.\"",
          "key": "c18"
        },
        {
          "type": "choice",
          "label": "Crafting: Time Pearl",
          "speaker": null,
          "text": "A measure of time calc, a glass sphere, steady pressure from both palms. Get it right and the sphere seals itself around the calc. Get it wrong and the calc clouds and drains away. Slow and careful, or more spheres and more losses.",
          "choices": [
            {
              "id": "patient",
              "label": "Take your time",
              "check": {
                "base": 0.55,
                "mods": [],
                "min": 0.15,
                "show": "odds",
                "attempts": 2,
                "perSuccess": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ]
              },
              "success": {
                "result_text": "You go slowly, and both spheres seal. Two pearls, faintly heavier than they should be. James looks at them for slightly longer than necessary. \"Adequate,\" he says, and logs it.",
                "effects": [],
                "goto": {
                  "branch": "b21"
                }
              },
              "bySuccesses": {
                "1": {
                  "result_text": "You go slowly. The first sphere clouds. The second doesn't: the glass closes over the calc with a small click. One pearl. James says nothing, which you're starting to understand is praise.",
                  "effects": [],
                  "goto": {
                    "branch": "b21"
                  }
                }
              },
              "fail": {
                "result_text": "You go slowly. It doesn't help. Both spheres cloud and drain while you're still being careful with them. James logs them. Then he takes a pearl from his own tray and sets it by your elbow, without looking at you.",
                "effects": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ],
                "goto": {
                  "branch": "b21"
                }
              }
            },
            {
              "id": "rush",
              "label": "Rush it",
              "check": {
                "base": 0.3,
                "mods": [],
                "min": 0.15,
                "show": "odds",
                "attempts": 4,
                "perSuccess": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ]
              },
              "success": {
                "result_text": "Four spheres. Four pearls. James puts his pen down. He looks at the pearls, then at you, the way he looked at you over the jar. He doesn't say anything. He picks the pen back up.",
                "effects": [],
                "goto": {
                  "branch": "b21"
                }
              },
              "bySuccesses": {
                "1": {
                  "result_text": "You go fast. Three spheres cloud. The fourth seals, more or less by accident. James holds it to the light, turns it once, and puts it on your side. \"Less pressure at the edge. Fewer of those.\"",
                  "effects": [],
                  "goto": {
                    "branch": "b21"
                  }
                },
                "2": {
                  "result_text": "You go fast. Two cloud, two seal. James logs the losses without comment and lines the pearls up on your side of the bench.",
                  "effects": [],
                  "goto": {
                    "branch": "b21"
                  }
                },
                "3": {
                  "result_text": "You go fast, and it mostly works. Three pearls seal; the fourth clouds at the last second. James looks at the three for a while. \"Hm,\" he says. From him, that's a lot.",
                  "effects": [],
                  "goto": {
                    "branch": "b21"
                  }
                }
              },
              "fail": {
                "result_text": "You go fast. Four spheres, four clouds, four grey puddles of calc on the bench. James logs each one in silence. Then he sets a pearl from his own tray by your elbow. \"Less pressure at the edge. Next time.\"",
                "effects": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ],
                "goto": {
                  "branch": "b21"
                }
              }
            },
            {
              "id": "askWatch",
              "label": "Ask James to watch",
              "check": {
                "base": 0.5,
                "mods": [],
                "min": 0.15,
                "show": "odds"
              },
              "success": {
                "result_text": "\"Would you watch?\" James looks at you over his glasses for a long moment. Then he pulls up a stool. \"Thumbs further apart. Further. There.\"",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "jamesWatching",
                    "value": true
                  },
                  {
                    "op": "relation",
                    "contact": "james",
                    "value": 3
                  }
                ]
              },
              "fail": {
                "result_text": "\"Would you watch?\" James sighs, at length, and goes back to his ledger. \"I'm not your mother. The calc is on the bench.\"",
                "effects": []
              }
            }
          ],
          "key": "c19"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The calc is measured out. The spheres are lined up on the bench.",
          "choices": [
            {
              "id": "patient",
              "label": "Take your time",
              "check": {
                "base": 0.55,
                "mods": [
                  {
                    "flag": "jamesWatching",
                    "add": 0.1,
                    "label": "James is watching"
                  }
                ],
                "min": 0.15,
                "show": "odds",
                "attempts": 2,
                "perSuccess": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ]
              },
              "success": {
                "result_text": "You go slowly, and both spheres seal. Two pearls, faintly heavier than they should be. James looks at them for slightly longer than necessary. \"Adequate,\" he says, and logs it.",
                "effects": []
              },
              "bySuccesses": {
                "1": {
                  "result_text": "You go slowly. The first sphere clouds. The second doesn't: the glass closes over the calc with a small click. One pearl. James says nothing, which you're starting to understand is praise.",
                  "effects": []
                }
              },
              "fail": {
                "result_text": "You go slowly. It doesn't help. Both spheres cloud and drain while you're still being careful with them. James logs them. Then he takes a pearl from his own tray and sets it by your elbow, without looking at you.",
                "effects": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ]
              }
            },
            {
              "id": "rush",
              "label": "Rush it",
              "check": {
                "base": 0.3,
                "mods": [
                  {
                    "flag": "jamesWatching",
                    "add": 0.1,
                    "label": "James is watching"
                  }
                ],
                "min": 0.15,
                "show": "odds",
                "attempts": 4,
                "perSuccess": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ]
              },
              "success": {
                "result_text": "Four spheres. Four pearls. James puts his pen down. He looks at the pearls, then at you, the way he looked at you over the jar. He doesn't say anything. He picks the pen back up.",
                "effects": []
              },
              "bySuccesses": {
                "1": {
                  "result_text": "You go fast. Three spheres cloud. The fourth seals, more or less by accident. James holds it to the light, turns it once, and puts it on your side. \"Less pressure at the edge. Fewer of those.\"",
                  "effects": []
                },
                "2": {
                  "result_text": "You go fast. Two cloud, two seal. James logs the losses without comment and lines the pearls up on your side of the bench.",
                  "effects": []
                },
                "3": {
                  "result_text": "You go fast, and it mostly works. Three pearls seal; the fourth clouds at the last second. James looks at the three for a while. \"Hm,\" he says. From him, that's a lot.",
                  "effects": []
                }
              },
              "fail": {
                "result_text": "You go fast. Four spheres, four clouds, four grey puddles of calc on the bench. James logs each one in silence. Then he sets a pearl from his own tray by your elbow. \"Less pressure at the edge. Next time.\"",
                "effects": [
                  {
                    "op": "add_item",
                    "item": "timePearl",
                    "qty": 1
                  }
                ]
              }
            }
          ],
          "key": "c20"
        }
      ],
      "then": {
        "branch": "b21"
      }
    },
    "b21": {
      "title": "Two hours later",
      "cards": [
        {
          "type": "resolution",
          "label": "Two hours later",
          "speaker": null,
          "text": "James wipes the bench down, caps the jar and puts it back on its shelf. Then he slides a battered crafting kit across to you.",
          "key": "c21"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": "James",
          "text": "\"The kit is payment. Whatever's on your side of the bench is yours.\" A pause. \"Keep practising and you may yet make more than a living out of this.\"",
          "choices": [
            {
              "id": "leaveTold",
              "label": "Leave",
              "requires": {
                "flag": "toldJamesJar"
              },
              "effects": [],
              "result_text": "The shutter comes down behind you. A battered kit, a pocket that clinks a little, and somewhere in James's ledger, a line about you. Archie will want to know how it went."
            },
            {
              "id": "leaveHid",
              "label": "Leave",
              "requires": {
                "flag": "hidJar"
              },
              "effects": [],
              "result_text": "At the shutter James says, without looking up, \"Next time a jar moves for you, mention it.\" Then the shutter comes down behind you. Archie will want to know how it went."
            }
          ],
          "key": "c22"
        }
      ]
    }
  }
}
```

## What changed vs. proposal 2 / current `james_meeting.json`

- `id` unchanged. No `at` (as current). Event has no images, so nothing to pin.
- **`on_complete`:** `add_item timePearl 2` removed. Pearls now come from `perSuccess` (+ the 0-count floor). Everything else is unchanged.
- **Card types.** The `craft` card becomes the pace `choice` (card 18). It loses the `craft` panel styling (`event.gd` `_style_card`), and the label "Crafting: Time Pearl" stays. James's jar card (14) and payment card (21) become `choice` cards with `speaker: "James"`.
- **Moved beat.** The jar choice sits after Archie leaves, on the jar James sets on the bench (proposal 2 already put it there). The first jar movement (card 5) and James's look (card 6) stay before, so the reason he keeps you back is unchanged.
- **Cut / merged.** "I've never made one" (You) merged into James's explainer. "It isn't really a question" folded into the Poundland card ("You don't answer."). Proposal 2's "Your first sphere clouds over" removed (it pre-empted the roll). The "Two hours later" card no longer hands over "two good pearls". Proposal 2's ungrammatical payment line is fixed. The old final card is now the closing choice's result.
- **Label.** Card 0 `Midday — Bermondsey` → `{today} — Bermondsey` (buyer proposal note). "Behind the Costcutter" → "beside the halal supermarket" (buyer proposal SMS).
- **New flags** (camelCase, matching `metJames`/intro proposal 3): `toldJamesJar`, `hidJar`, `jamesWatching`. Review §18.4 named them `told_james_jar`/`hid_jar`; renamed for consistency. Choice memory also records `tell`/`sayNothing`, `patient`/`rush`/`askWatch` with `successes`.
- **Card 19 duplicates card 18's pace outcomes**, because the engine has no shared outcome reference. Text is identical, without the `goto`s (it falls through to card 20).

## Cards needing new art (→ event-storyboard)

The event has no art today, so none of this is needed to ship. Review §8 flags the current James plate (a study, not a storage unit) as a mismatch. Candidate plates, in priority order:

1. Card 5/14: the TIME jar, calc pressed to the glass nearest your hand (it serves both jar beats).
2. Card 0: storage unit shutter beside the halal supermarket, Archie checking the street.
3. Card 18: the bench, with gloves, spheres and the ledger.
4. `rush` 4-pearl result: James with his pen down, looking at you.
5. Card 21 / `leaveHid`: James at the shutter, not looking up.

## Open points for review

- **Tell reveal invents canon.** "One person in a few thousand. I have met two." and "They'll want to weigh you" say this is rare and exploitable, without explaining it. Is that inside what you want James to reveal at first meeting? A softer version: "It does that, now and then. Not for many." + the warning.
- **0-pearl floor.** Proposed above (James's pearl on `fail`). Drop it for a true 0.
- **Fake choice at the exit.** Card 21 shows exactly one "Leave" option, picked by `requires` flag. That's an engine-native way to branch closing text, but it is a one-button choice. The alternative is plain closing text with no callback, which loses "James notices anyway".
- **`askWatch` fail = no watching.** I read "James sighs" as him refusing, so card 19 runs without the mod. The player still picks a pace there, so the visit to card 19 is identical apart from the odds.
- **Proposal 2's "Gloves." line.** Kept, but "That wasn't a compliment" was cut so the card has room for the jar. Restore it if the jar card can afford ~5 words (currently ~50).
- **Possible third joke.** "which you're starting to understand is praise" and "From him, that's a lot." are one-path lines. Cut them if they read as extra anchors.
- **Craft styling.** Card 18 loses the `craft` panel. If that styling matters, keep a `craft` card for the instruction and add a separate pace choice (+1 card).
- **Carried from proposal 2, unresolved:** physics vs life calc (proposal 2's notes say physics, its text says life, and this proposal keeps the text). £120 pearl price. Archie's eye-rub by the shutter. "Nobody who's ever shortchanged me". The parcel simile ("as if it noticed you" is borderline a second). "Second only to gold".
- **Handoff.** `archie_craft_chat` currently has the player say "it worked" unconditionally. Ticket 16 should vary that by pearl count or by the `askWatch`/floor path.

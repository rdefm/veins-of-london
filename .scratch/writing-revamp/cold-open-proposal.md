# cold_open — imported from data/events/cold_open.json

```json
{
  "id": "cold_open",
  "at": {
    "block": "evening",
    "advance": true
  },
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "coldOpenSeen",
      "value": true
    },
    {
      "op": "set_flag",
      "flag": "rentGoal",
      "value": true
    },
    {
      "op": "start_event",
      "event": "pub"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": "{today} — Whitechapel",
          "speaker": null,
          "text": "Rent's due Monday. You have £40, and this morning's interviewer has promised to keep your details on file. Archie, an old mate, said he might have work. So: Tuesday night, behind a chicken shop on Mile End Road.",
          "image": "res://assets/events/intro/intro_card1.png",
          "key": "c1"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "He's whistling, a Tesco bag hooked on one finger. \"Two blokes, cash, in and out before the chicken shop shuts. You just stand there looking like you'd be a pain to fight. If I say leg it, you leg it. Don't wait for me.\"",
          "key": "c2"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "You",
          "text": "\"I don't look like I'd be a pain to fight.\"",
          "key": "c3"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": "Archie",
          "text": "\"Pretend you're Vinnie Jones in his prime, then.\" He looks you up and down. \"Bit more of a Mr Bean vibe, but you make do with what you've got.\" He holds out a fist. \"You in?\"",
          "image": "res://assets/events/intro/intro_card5.png",
          "choices": [
            {
              "id": "stand",
              "label": "\"I'll stand there.\"",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "introBrave",
                  "value": true
                }
              ],
              "result_text": "You bump the fist. \"Lovely,\" says Archie, and goes back to whistling."
            },
            {
              "id": "askBuyers",
              "label": "\"Who are the buyers?\"",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "introAskedQuestions",
                  "value": true
                }
              ],
              "result_text": "Archie lowers the fist. \"Two lads from Romford. Bought off me twice. Pay cash, don't chat.\" He thinks about it. \"One of them's got a cousin. Never met the cousin.\""
            },
            {
              "id": "wantHalf",
              "label": "\"I want half.\"",
              "effects": [
                {
                  "op": "relation",
                  "contact": "archie",
                  "value": -3
                },
                {
                  "op": "set_flag",
                  "flag": "introWantsHalf",
                  "value": true
                }
              ],
              "result_text": "\"You were getting half.\" Archie looks at you for a long second, fist still out. \"Sixty-forty, then. Your way. Don't make a habit of it.\""
            }
          ],
          "key": "c4"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": "Archie",
          "text": "He pulls something from his pocket and presses it into your hand: a small glass hourglass, warm. \"Keep this to hand. If it goes bad, break it.\" He doesn't say what it does. He's already watching the road.",
          "choices": [
            {
              "id": "takeRewind",
              "label": "Take it",
              "effects": [
                {
                  "op": "add_item",
                  "item": "rewind",
                  "qty": 1,
                  "tier": 5,
                  "equip": true
                }
              ],
              "result_text": "You put it in your pocket, where it keeps being warm."
            }
          ],
          "key": "c5"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "The buyers arrive in a grey Vauxhall. Three of them, one more than Archie mentioned. He stops whistling.",
          "image": "res://assets/events/intro/intro_card6.png",
          "key": "c6"
        },
        {
          "type": "tension",
          "label": "It goes wrong",
          "speaker": null,
          "text": "The third man gets out last, in no hurry. The other two straighten up. They call him Nick. He holds out a hand for the Tesco bag, looks in, and hands it back. \"Light.\" Nobody has said a number. One of the others opens a Stanley knife.",
          "image": "res://assets/events/intro/intro_card7.png",
          "key": "c7"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Nick",
          "text": "He looks you over and takes his time about it. \"New one. Lovely. Stay there, newbie. You can watch.\" He's smiling before the sentence is finished.",
          "key": "c8"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Nick cracks his knuckles, one at a time. Archie edges half a step in front of you.",
          "image": "res://assets/events/intro/intro_card8.png",
          "choices": [
            {
              "id": "brace",
              "label": "Brace",
              "effects": [
                {
                  "op": "start_scripted_fight",
                  "script": {
                    "seed": 5,
                    "enemyFirst": true,
                    "intro": [
                      "Nick doesn't wait for anyone to be ready."
                    ],
                    "enemies": [
                      {
                        "name": "Nick",
                        "hpMax": 120,
                        "attackMin": 9,
                        "attackMax": 11,
                        "level": 1,
                        "speed": 60,
                        "template": "mugger",
                        "moveLevels": {
                          "strike": 1,
                          "guard": 1,
                          "feint": 1,
                          "stun": 1,
                          "legIt": 1
                        },
                        "plans": [
                          [
                            {
                              "move": "strike",
                              "target": 1
                            },
                            {
                              "move": "strike",
                              "target": 0
                            }
                          ],
                          [
                            {
                              "move": "strike",
                              "target": 0
                            },
                            {
                              "move": "strike",
                              "target": 0
                            }
                          ]
                        ]
                      }
                    ],
                    "allies": [
                      {
                        "name": "Archie",
                        "hpMax": 60,
                        "attackMin": 3,
                        "attackMax": 3,
                        "level": 1,
                        "speed": 99,
                        "sprite": "archie",
                        "slots": [
                          {
                            "recipe": "timePearl",
                            "tier": 2
                          }
                        ],
                        "moveLevels": {
                          "strike": 1,
                          "guard": 1,
                          "feint": 1,
                          "stun": 1,
                          "legIt": 1
                        },
                        "plans": [
                          [
                            "guard",
                            "guard"
                          ]
                        ]
                      }
                    ],
                    "forcedHits": [
                      {
                        "actor": 2,
                        "target": 1,
                        "crit": true,
                        "ko": true
                      }
                    ],
                    "coach": {
                      "lessons": {
                        "1": "Archie's down. Nick's coming for you.",
                        "2": "Read what he's about to do.",
                        "3": "You can't win this. Look at the bar."
                      },
                      "allowed": {
                        "1": [
                          "strike",
                          "guard",
                          "feint",
                          "stun",
                          "legIt"
                        ],
                        "2": [
                          "strike",
                          "guard",
                          "feint",
                          "stun",
                          "legIt"
                        ],
                        "3": [
                          "strike",
                          "guard",
                          "feint",
                          "stun",
                          "legIt"
                        ]
                      }
                    },
                    "lockBelowHp": 20,
                    "prompt": "\"Break it. Now!\" — Archie",
                    "post": {
                      "allyPlans": {
                        "1": [
                          "guard",
                          {
                            "move": "timePearl",
                            "slot": 0
                          }
                        ]
                      },
                      "playerPlan": [
                        "guard",
                        "legIt"
                      ]
                    },
                    "resumeCard": 9
                  }
                }
              ],
              "result_text": ""
            }
          ],
          "key": "c9"
        },
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Your eyes dart left and right, confused. Adrenaline and fear pump through your body. Your attackers are in a bubble, slowed like a video buffering. Nick is still mid-sneer.",
          "image": "res://assets/events/intro/intro_card9.png",
          "key": "c10"
        },
        {
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "Archie walks calmly but briskly around them. \"Coming, or what?\"",
          "key": "c11"
        },
        {
          "type": "narration",
          "label": "Four streets later",
          "speaker": null,
          "text": "A closed launderette. Archie leans on the shutter, eyes streaming, the Tesco bag still hooked on his finger. \"Pub,\" he says.",
          "key": "c12"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "at",
      "on_complete",
      "cards"
    ],
    "cards": {
      "c1": [
        "type",
        "label",
        "speaker",
        "text",
        "image"
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c4": [
        "type",
        "label",
        "speaker",
        "text",
        "image",
        "choices"
      ],
      "c5": [
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c6": [
        "type",
        "label",
        "speaker",
        "text",
        "image"
      ],
      "c7": [
        "type",
        "label",
        "speaker",
        "text",
        "image"
      ],
      "c8": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c9": [
        "type",
        "label",
        "speaker",
        "text",
        "image",
        "choices"
      ],
      "c10": [
        "type",
        "label",
        "speaker",
        "text",
        "image"
      ],
      "c11": [
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c12": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "cold_open.json",
  "_liveHash": "de4ea172"
}
```

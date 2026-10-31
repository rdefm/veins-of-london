# raid_shop — prose proposal (ticket 28)

Replaces every placeholder in `data/events/raid_shop.json`. Structure, effects, checks, gotos and keys are unchanged; only `text`, `result_text`, cover texts, observation texts and two option labels change.

## What changed and why

- **The goal is stated up front.** The intro says where the vein is (the cellar, under the back room), who's guarding it (the owner's men, posing as stock staff), and the stakes (the shop is still trading; everyone else is a witness; going loud happens in front of a street).
- **The perimeter card is a map.** `s_front` spells out each route as a chain of rooms (front: till → staff door → stockroom → cellar stairs; back: yard → yard door → stockroom → stairs). `s_flap` says why the flap is worth the risk (it skips the till, stockroom and stairs) and why it's risky (busy street, bus stop).
- **Every obstacle card names the obstacle and what's past it,** so each option reads as a way past this one thing towards the cellar.
- **Every outcome says what happened and where you are now.** In this graph a failed quiet check still gets you through but spotted (fail → `s_seen_*` → window → back on the route). The fail lines now say exactly that ("You're through, but not unseen"), so the window card that follows makes sense.
- **Witnesses are people, not guards.** `s_win_wit` explains why they matter: you can't fight them, but they can tell someone. Daniela (till worker) has a want (the end of her shift), a tell (scans without looking) and a quiet act of complicity on the getaway.
- **The guards have a disguise you can recognise:** "a man in a shop fleece", used consistently across every route.

## Six goals (writing-guide §1)

1. **Hook:** a shop still trading, a queue of two, a vein under it, guards hidden in the stock.
2. **Focus:** what's at risk (witnesses, the owner, being watched for days after) is said on the cards where it bites; `s_claim` spells out claim vs loot.
3. **Brief:** cards ≤ ~55 words; results ≤ ~35.
4. **Funny twice:** anchors: the toilet ("You don't plan to touch anything on the left"), the boiler. Small deadpan elsewhere ("Londoners don't look at the pavement", the crisp offer under Pan's Rapture, backing out "like a customer who couldn't find what they wanted").
5. **People:** Daniela; the regular with his scratchcards; the bored men in fleeces.
6. **Memorable moment:** you kneel on the vein while the till drawer opens and shuts over your head. On the getaway, Daniela sees you, looks at the clock instead and lets you walk out.

## Unchanged / changed

- `id`, `on_complete`, effects, checks, gotos, keys, images: unchanged.
- **Labels changed (2):** `Read the gaps…` → `Other ways in…`, `Go between pallet runs` → `Go in a quiet spell`. `tests/test_raid_shop.gd` picks `Read the gaps…` 7 times; apply must update those strings.
- **Observation variants added (2):** physics tier 1 + `cellarFlap` (the flap option gates on physics ≥ 1, so the tier-1 read now mentions the flap); fate tier 1 + `cameras` (tier 1 used to mention CCTV even on sites without one).
- Fate tier 2 base no longer mentions the ward. The ward line comes from `Observation.ward_line()`, and the old text was wrong on unwarded sites.

## Open points for review

- **Daniela** is a new named character (her name badge). Cut the name if you'd rather she stay "the woman on the till".
- **Police** aren't named. Stakes are put as "they can tell someone" or "they're not dialling a friend", because the only mechanical consequences are reinforcements, relation and `siteWary`. Say if you want an explicit police line.
- **Shop type:** the prose works for off-licence, Tesco Metro and bookies alike (till, fridges, crisps, scratchcards, a drayman). There's no context token for the shop type.
- **`s_resume` → `s_resume2`** shows two filler cards in a row after every window or fight. Cutting one needs a goto change (point `s_resume` straight at `s_resume2`'s flag targets). That's structural, so it isn't done here.
- **Fixed times** ("on the hour", "forty minutes", "eleven minutes") are flavour only, not mechanics.
- **Fate t2 + cameras** says the camera never sees the staff door. That's a reinterpretation of spec §5's "records nothing", so it fits the blind-spot option and doesn't imply the camera is harmless.

```json
{
  "id": "raid_shop",
  "repeatable": true,
  "reinforceClock": 2,
  "fightPresets": {
    "veinGuards": {
      "guards": "vein",
      "template": "veinGuard",
      "situational": [
        {
          "if": {
            "observed": {
              "id": "raid",
              "ore": "physics",
              "atLeast": 1
            }
          },
          "fleeBoost": 0.25
        },
        {
          "if": {
            "observed": {
              "id": "raid",
              "ore": "life",
              "atLeast": 1
            }
          },
          "oneAtATime": true
        },
        {
          "if": {
            "observed": {
              "id": "raid",
              "ore": "time",
              "atLeast": 1
            }
          },
          "sight": 2
        },
        {
          "if": {
            "observed": {
              "id": "raid",
              "ore": "fate",
              "atLeast": 1
            }
          },
          "firstStrike": true
        }
      ]
    }
  },
  "observations": {
    "raid": {
      "mods": [],
      "ward": {
        "ore": "fate",
        "atLeast": 1
      },
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "The yard door's hinge pins are on the outside. You can place the vein to the yard: under the back room, against the far wall.",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cellarFlap"
                    }
                  },
                  "text": "The yard door's hinge pins are on the outside, and the pavement cellar flap is rotten along one edge. You can place the vein to the yard: under the back room, against the far wall."
                }
              ]
            },
            {
              "base": 0.55,
              "text": "The yard door round the back is old: soft paint, a warped frame, and a lock newer than the wood.",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cellarFlap"
                    }
                  },
                  "text": "The yard door round the back is old, and the cellar flap in the pavement has seen better decades."
                }
              ]
            }
          ],
          "miss": "Plate glass, a shutter rolled up for the evening, a door with a chime. Nothing you can read past that."
        },
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "One woman on the till, and a regular at the counter who's been \"just going\" for forty minutes. In the back, men in shop fleeces stocking the shelves, more men than the shelves need. One of them keeps stepping out to the yard for a smoke."
            },
            {
              "base": 0.55,
              "text": "There's more than one person in the back. The man at the counter isn't buying anything, and somebody keeps stepping out the back for a smoke."
            }
          ],
          "miss": "Customers, staff, a man at the counter. From out here you can't tell who works for the shop and who works for the cellar."
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "The woman on the till would accept any story that means she doesn't have to deal with it. The men in the back are bored, and boredom makes people easy to talk past."
            },
            {
              "base": 0.55,
              "text": "The woman on the till hates this job, quietly and in detail."
            }
          ],
          "miss": "Tired faces under strip lights. Nothing you can use."
        },
        "time": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Stock comes in round the back, and the drayman comes on the hour. He props the pavement flap open while he unloads, and leaves it open between crates.",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cameras",
                      "atLeast": 1
                    }
                  },
                  "text": "The drayman comes on the hour and props the pavement flap open between crates. The camera over the till pans on a slow loop, and you can count it."
                }
              ]
            },
            {
              "base": 0.55,
              "text": "Stock comes in round the back on some kind of schedule. The back room gets busy, then quiet, then busy again."
            }
          ],
          "miss": "People come and go. You can't make a pattern of it."
        },
        "fate": {
          "tiers": [
            {
              "base": 0.25,
              "text": "It's a bad night for this shop's luck. The card machine has gone down twice already, and it's due again.",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cameras",
                      "atLeast": 1
                    }
                  },
                  "text": "The camera over the till is aimed at the queue, not the staff door. There's a stripe of floor beside the counter it has never once seen. And the card machine is due to go down again."
                }
              ]
            },
            {
              "base": 0.55,
              "text": "Small things keep going wrong in this shop. The door chime sticks, and the card machine sulks.",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cameras",
                      "atLeast": 1
                    }
                  },
                  "text": "The CCTV over the till isn't quite right. It's something about where it's pointing."
                }
              ]
            }
          ],
          "miss": "No luck in the air either way. Just a shop."
        }
      }
    }
  },
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "sReinfOpen",
      "value": false
    },
    {
      "op": "set_flag",
      "flag": "sCust",
      "value": false
    },
    {
      "op": "set_flag",
      "flag": "sYard",
      "value": false
    },
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "s_intro",
          "type": "tension",
          "label": "{today} — The approach",
          "speaker": null,
          "observe": "raid",
          "text": "A late-opening shop, still trading: strip lights, a queue of two, a bus stop outside. The vein is in the cellar, under the back room. There will be guards nearby; everyone else in there is a witness. Get this wrong and you get it wrong in front of a whole street."
        },
        {
          "key": "s_front",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "You can make out 2 ways in. 1) front door: past the till, through the staff door, across the stockroom, down the stairs. 2) round the back: the yard, the yard door, the same stockroom. The front is the easy part. It's also where everyone can see you.",
          "choices": [
            {
              "label": "Walk in as a customer",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sCust",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sYard",
                  "value": false
                }
              ],
              "result_text": "You go in the front, like anyone wanting milk at this hour.",
              "goto": {
                "branch": "b4"
              }
            },
            {
              "label": "Round the back",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sCust",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sYard",
                  "value": true
                }
              ],
              "result_text": "You walk past the shop and turn down the side passage, away from the lights.",
              "goto": {
                "branch": "b11"
              }
            },
            {
              "label": "Other ways in…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b3"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b3"
      }
    },
    "b3": {
      "title": "From card 3",
      "cards": [
        {
          "key": "s_front2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "What you read buys you other ways in. Some skip the shop altogether.",
          "choices": [
            {
              "label": "The cellar flap",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "security": {
                      "feature": "cellarFlap"
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sCust",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sYard",
                  "value": false
                }
              ],
              "result_text": "You stay out front, on the pavement, by the flap that drops straight into the cellar.",
              "goto": {
                "branch": "b15"
              }
            },
            {
              "label": "Open a Wormhole",
              "requires": {
                "all": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    }
                  },
                  {
                    "item": "wormhole",
                    "optional": true
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.85,
                "mods": [
                  {
                    "item": "wormhole",
                    "optional": true,
                    "label": "Wormhole",
                    "effect": {
                      "kind": "unlock"
                    }
                  }
                ]
              },
              "success": {
                "result_text": "The street folds. You step out in the cellar with the vein under your feet and the shop still trading over your head.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "The fold drops you in the cellar, and into a stack of bottles. Upstairs, somebody stops talking.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "atLeast": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b4"
      }
    },
    "b4": {
      "title": "From card 4",
      "cards": [
        {
          "key": "s_in_cust",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "The door chimes. Three aisles, a humming fridge, a regular at the counter in no hurry to leave. The staff door is behind the till."
        }
      ],
      "then": [
        {
          "if": {
            "security": {
              "feature": "cameras",
              "atLeast": 1
            }
          },
          "branch": "b35"
        },
        {
          "branch": "b5"
        }
      ]
    },
    "b5": {
      "title": "From card 5",
      "cards": [
        {
          "key": "s_till",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The woman on the till is scanning a meal deal without looking at it. Her badge says DANIELA. The staff door is beside her, propped open on a box of receipts. To get through it, you need her to be looking somewhere else, or not caring.",
          "choices": [
            {
              "label": "Ask for the toilet",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "\"Through the back, on the left. Don't touch anything.\" You don't plan to touch anything on the left.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b51"
                }
              },
              "fail": {
                "result_text": "\"No public toilet.\" She says it to your back, because you're already through the staff door. Now she's watching it.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Spin her the story she wants",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "all": [
                      {
                        "flag": "sCust"
                      },
                      {
                        "security": {
                          "feature": "cameras",
                          "atLeast": 1
                        }
                      }
                    ],
                    "add": 0.08,
                    "label": "Tuned for the camera"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You say you're here about the boiler. She's already pointing at the back. Nobody wants to be the one who knows about the boiler.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b51"
                }
              },
              "fail": {
                "result_text": "She asks which company sent you. You name one. She writes it down, then watches you go through the door.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Wait until she's serving the regular",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "all": [
                      {
                        "flag": "sCust"
                      },
                      {
                        "security": {
                          "feature": "cameras",
                          "atLeast": 1
                        }
                      }
                    ],
                    "add": 0.08,
                    "label": "Tuned for the camera"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "The regular starts on his scratchcards, one at a time, with commentary. Daniela can't get away from him. You walk through the staff door.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b51"
                }
              },
              "fail": {
                "result_text": "The regular wins two quid and goes quiet to enjoy it. In the silence, Daniela looks up at you with your hand on the staff door.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b6"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b6"
      }
    },
    "b6": {
      "title": "From card 6",
      "cards": [
        {
          "key": "s_till2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The staff door is still propped open, and Daniela is still beside it.",
          "choices": [
            {
              "label": "Hope the card machine goes down",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "The card machine says CONNECTING and keeps saying it. The queue turns on Daniela, and nobody's watching the door.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b51"
                }
              },
              "fail": {
                "result_text": "The card machine works first time, for once. Daniela looks up, pleased, straight at you.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Prophet's Breath: know when she's busy",
              "requires": {
                "item": "prophetsBreath",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "prophetsBreath",
                  "optional": true,
                  "label": "Prophet's Breath",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "You know the exact second she'll turn to the cigarette cabinet. When she does, you're already through the staff door.",
              "goto": {
                "branch": "b51"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b7"
      }
    },
    "b7": {
      "title": "From card 7",
      "cards": [
        {
          "key": "s_back",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Nobody's guarding the stockroom. But staff come back here for stock every few minutes, and a stranger among the shelves takes some explaining. The cellar door is at the far end.",
          "choices": [
            {
              "label": "Go in a quiet spell",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "all": [
                      {
                        "flag": "sCust"
                      },
                      {
                        "security": {
                          "feature": "cameras",
                          "atLeast": 1
                        }
                      }
                    ],
                    "add": 0.08,
                    "label": "Tuned for the camera"
                  },
                  {
                    "flag": "sYard",
                    "add": 0.08,
                    "label": "Tuned for the long way"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You wait for the lull between restocks and cross the stockroom in it.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b52"
                }
              },
              "fail": {
                "result_text": "The lull is shorter than you thought. You're halfway across when someone comes through with a box.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Keep to the blind side of the shelving",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "all": [
                      {
                        "flag": "sCust"
                      },
                      {
                        "security": {
                          "feature": "cameras",
                          "atLeast": 1
                        }
                      }
                    ],
                    "add": 0.08,
                    "label": "Tuned for the camera"
                  },
                  {
                    "flag": "sYard",
                    "add": 0.08,
                    "label": "Tuned for the long way"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You keep a cage of stock between you and the doorway all the way to the cellar door.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b52"
                }
              },
              "fail": {
                "result_text": "You come round the end of the shelving into someone coming the other way.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Hope nobody's restocking",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "Nobody's restocking. Judging by the shelves, nobody has in a while.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b52"
                }
              },
              "fail": {
                "result_text": "Somebody is, and they're behind the next cage.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b8"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b8"
      }
    },
    "b8": {
      "title": "From card 8",
      "cards": [
        {
          "key": "s_back2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or let something you brought do the work.",
          "choices": [
            {
              "label": "Prophet's Breath: know where they are",
              "requires": {
                "item": "prophetsBreath",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "prophetsBreath",
                  "optional": true,
                  "label": "Prophet's Breath",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "You know where everyone in the building will be for the next minute. None of them will be here.",
              "goto": {
                "branch": "b52"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
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
          "key": "s_lock",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The cellar door is locked, and the lock is newer than the door. Somebody spent money back here, and not on the shop.",
          "choices": [
            {
              "label": "Pick it quiet",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "all": [
                      {
                        "flag": "sCust"
                      },
                      {
                        "security": {
                          "feature": "cameras",
                          "atLeast": 1
                        }
                      }
                    ],
                    "add": 0.08,
                    "label": "Tuned for the camera"
                  },
                  {
                    "flag": "sYard",
                    "add": 0.08,
                    "label": "Tuned for the long way"
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "The lock turns over. You ease the door open on a flight of stone steps and go down.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "The lock opens, but the pick slips first and the door rattles in its frame. Behind you, someone says \"Oi.\"",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Hope it isn't locked",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "Somebody left it on the latch for a delivery and forgot. You go down.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "It's locked, but the frame is soft. It gives when you lean on it, and not quietly.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Rougher ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b10"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b10"
      }
    },
    "b10": {
      "title": "From card 10",
      "cards": [
        {
          "key": "s_lock2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or make some noise, and hope the shop makes more.",
          "choices": [
            {
              "label": "Walk down",
              "requires": {
                "security": {
                  "feature": "tier",
                  "is": "none"
                },
                "display": "hide"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": true
                }
              ],
              "result_text": "No lock, just a hook and eye. You lift the hook and go down.",
              "goto": {
                "branch": "b41"
              }
            },
            {
              "label": "Force the door",
              "requires": {
                "security": {
                  "feature": "locks"
                },
                "display": "hide"
              },
              "check": {
                "base": 0.8,
                "mods": [
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  }
                ]
              },
              "success": {
                "result_text": "You put your shoulder into it. The frame splits and the door opens on the cellar steps.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "atLeast": 2,
                    "cover": {
                      "base": 0.35,
                      "text": "Out front, the fridges hum and the radio keeps playing. Nobody comes to look."
                    }
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "It gives on the third go, with a crack like a dropped crate. Everyone in the building heard that.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              }
            },
            {
              "label": "Blast the door",
              "requires": {
                "all": [
                  {
                    "item": "blast",
                    "optional": true
                  },
                  {
                    "security": {
                      "feature": "locks"
                    }
                  }
                ],
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": true
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "Out front, the fridges hum and the radio keeps playing. Nobody comes to look."
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                }
              ],
              "result_text": "The door comes off and goes down the stairs ahead of you.",
              "goto": {
                "branch": "b41"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b11"
      }
    },
    "b11": {
      "title": "From card 11",
      "cards": [
        {
          "key": "s_yard",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Round the back: bins, flattened boxes, a stack of empty crates. A man in a shop fleece is having a smoke beside the yard door, which is the door you need. He isn't staff. He's watching the door more than his phone.",
          "choices": [
            {
              "label": "Wait for the smoker to finish",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.58,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "He grinds the cigarette out, checks his phone and goes back inside. The yard is yours, and so is the door.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b13"
                }
              },
              "fail": {
                "result_text": "He lights another off the first one and turns round to do it. He's looking right at you.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b21"
                }
              }
            },
            {
              "label": "Pose as the delivery",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "In the drayman's slot"
                  },
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You lift a crate off the stack and walk to the door like you're paid by the drop. He nods at the crate and goes back to his phone.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b13"
                }
              },
              "fail": {
                "result_text": "He asks where the van is. There isn't a van.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b21"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b12"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b12"
      }
    },
    "b12": {
      "title": "From card 12",
      "cards": [
        {
          "key": "s_yard2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or trust to luck, or to something you brought.",
          "choices": [
            {
              "label": "Hope he's gone in",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "He has. There's a cigarette end still smoking by the bins and nobody standing over it.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b13"
                }
              },
              "fail": {
                "result_text": "He hasn't. He's only round the corner, and now he's round it facing you.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b21"
                }
              }
            },
            {
              "label": "Prophet's Breath: know when he goes in",
              "requires": {
                "item": "prophetsBreath",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "prophetsBreath",
                  "optional": true,
                  "label": "Prophet's Breath",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "You know the second he'll turn to go in. You're behind the bins when he does, and at the door when it shuts.",
              "goto": {
                "branch": "b13"
              }
            },
            {
              "label": "Time Pearl: freeze him",
              "requires": {
                "item": "timePearl",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "timePearl",
                  "optional": true,
                  "label": "Time Pearl",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "He stops with the lighter halfway to his mouth. You walk past him to the door.",
              "goto": {
                "branch": "b13"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b13"
      }
    },
    "b13": {
      "title": "From card 13",
      "cards": [
        {
          "key": "s_door",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The yard door: old wood, painted so many times the gaps have filled in. It's locked from the inside. The stockroom is through it, and the cellar door beyond that.",
          "choices": [
            {
              "label": "Slide the hinge pins out",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.58,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "The pins come out with some persuasion and the door lifts off its hinges. You lean it against the wall and step into the stockroom.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b51"
                }
              },
              "fail": {
                "result_text": "The second pin sticks, then comes out all at once and rings off the step. The door's open, and someone inside heard it.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b22"
                }
              }
            },
            {
              "label": "Pick it",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "The lock's newer than the door and not as good as it looks. It turns, and you're in the stockroom.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b51"
                }
              },
              "fail": {
                "result_text": "The lock turns in the end, but the pick skids first and the whole door rattles. Someone inside heard that.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b22"
                }
              }
            },
            {
              "label": "Rougher ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b14"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b14"
      }
    },
    "b14": {
      "title": "From card 14",
      "cards": [
        {
          "key": "s_door2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or make some noise about it.",
          "choices": [
            {
              "label": "Walk in",
              "requires": {
                "security": {
                  "feature": "tier",
                  "is": "none"
                },
                "display": "hide"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "It isn't locked, only stuck. One shove and you're in the stockroom.",
              "goto": {
                "branch": "b51"
              }
            },
            {
              "label": "Force the door",
              "requires": {
                "security": {
                  "feature": "locks"
                },
                "display": "hide"
              },
              "check": {
                "base": 0.8,
                "mods": [
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  }
                ]
              },
              "success": {
                "result_text": "Paint and old wood. It gives on the second shove.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2,
                    "cover": {
                      "base": 0.35,
                      "text": "Out front, the fridges hum and the radio keeps playing. Nobody comes to look."
                    }
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b50"
                }
              },
              "fail": {
                "result_text": "It gives on the third, all at once, and slams into a cage of crisps.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b50"
                }
              }
            },
            {
              "label": "Blast the door",
              "requires": {
                "all": [
                  {
                    "item": "blast",
                    "optional": true
                  },
                  {
                    "security": {
                      "feature": "locks"
                    }
                  }
                ],
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "Out front, the fridges hum and the radio keeps playing. Nobody comes to look."
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                }
              ],
              "result_text": "The yard door stops being a door. Most of it lands in the stockroom ahead of you.",
              "goto": {
                "branch": "b50"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b15"
      }
    },
    "b15": {
      "title": "From card 15",
      "cards": [
        {
          "key": "s_flap",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The cellar flap: two iron-edged doors in the pavement, where deliveries go down the chute. It's the shortest way in. No till, no stockroom, no stairs. It's also on a busy street, in full view of the bus stop.",
          "choices": [
            {
              "label": "Take the flap while the drayman has it open",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    }
                  }
                ],
                "display": "disable"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "The drayman props the flap open and goes back to his van for the next crate. You go down the chute before he's back.",
              "goto": {
                "branch": "b17"
              }
            },
            {
              "label": "Lever the rotten flap",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.4,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "The rotten edge gives under the bar with a soft crunch. You lift the flap, drop through and let it down over your head.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b17"
                }
              },
              "fail": {
                "result_text": "The rotten edge goes all at once and the flap bangs on the pavement. You're through, but not unseen.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
                }
              }
            },
            {
              "label": "Hope no one on the street looks down",
              "check": {
                "base": 0.36,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "security": {
                      "feature": "tier",
                      "is": "none"
                    },
                    "add": 0.15,
                    "label": "Rickety site"
                  }
                ]
              },
              "success": {
                "result_text": "Londoners don't look at the pavement. You're down the chute before anyone does.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b17"
                }
              },
              "fail": {
                "result_text": "You're halfway down the chute when someone on the pavement stops walking.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b16"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b16"
      }
    },
    "b16": {
      "title": "From card 16",
      "cards": [
        {
          "key": "s_flap2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or the quick way, which is also the loud way, on a street full of people.",
          "choices": [
            {
              "label": "Blast the flap",
              "requires": {
                "item": "blast",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "A bus pulls away from the stop at the same moment and takes the noise with it."
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                }
              ],
              "result_text": "The flap goes up in two pieces and comes down in more. You're down the hole before the street has finished turning round.",
              "goto": {
                "branch": "b17"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b17"
      }
    },
    "b17": {
      "title": "From card 17",
      "cards": [
        {
          "key": "s_cellar",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "You land among barrels and boxes in the cellar. The till, the stockroom and the stairs are all over your head. Between you and the vein is one guard on a crate, half turned away from you.",
          "choices": [
            {
              "label": "Wait for the guard on the vein to turn",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.4,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "He turns to read a message on his phone. You're across the cellar before he's finished it.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "He turns, but the wrong way, and you're standing in the middle of the floor.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Hope he turns",
              "check": {
                "base": 0.36,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "He gets up to stretch, facing the wall. You're past him.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "He doesn't turn. He looks up, straight at the bottom of the chute.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b23"
                }
              }
            },
            {
              "label": "Prophet's Breath: know when he turns",
              "requires": {
                "item": "prophetsBreath",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "prophetsBreath",
                  "optional": true,
                  "label": "Prophet's Breath",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": true
                }
              ],
              "result_text": "You know which second he'll look at his phone. You move in that second.",
              "goto": {
                "branch": "b41"
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b18"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b18"
      }
    },
    "b18": {
      "title": "From card 18",
      "cards": [
        {
          "key": "s_cellar2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or stop him where he sits.",
          "choices": [
            {
              "label": "Time Pearl: freeze him",
              "requires": {
                "item": "timePearl",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "timePearl",
                  "optional": true,
                  "label": "Time Pearl",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": true
                }
              ],
              "result_text": "He stops mid-yawn. You walk round him to the vein.",
              "goto": {
                "branch": "b41"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b19"
      }
    },
    "b19": {
      "title": "From card 19",
      "cards": [
        {
          "key": "s_seen_till",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "Daniela looks up from the till, straight at you. Her hand goes under the counter, to the phone."
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b29"
        },
        {
          "branch": "b28"
        }
      ]
    },
    "b20": {
      "title": "From card 20",
      "cards": [
        {
          "key": "s_seen_flap",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "A woman at the bus stop has stopped scrolling. She's watching you, and so is her phone."
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b29"
        },
        {
          "branch": "b28"
        }
      ]
    },
    "b21": {
      "title": "From card 21",
      "cards": [
        {
          "key": "s_seen_yard",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "The smoker looks up, and keeps looking."
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b29"
        },
        {
          "branch": "b24"
        }
      ]
    },
    "b22": {
      "title": "From card 22",
      "cards": [
        {
          "key": "s_seen_door",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "The yard door opens from inside. A man in a shop fleece looks out at you."
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b29"
        },
        {
          "branch": "b24"
        }
      ]
    },
    "b23": {
      "title": "From card 23",
      "cards": [
        {
          "key": "s_seen_in",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "A door bangs, and a man in a shop fleece comes round the shelving with a box in his arms. He isn't staff. Staff don't look at you like that."
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "alert": {
                  "atLeast": 2
                }
              },
              {
                "security": {
                  "feature": "guards",
                  "atLeast": 1
                }
              }
            ]
          },
          "branch": "b31"
        },
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b29"
        },
        {
          "branch": "b26"
        }
      ]
    },
    "b24": {
      "title": "From card 24",
      "cards": [
        {
          "key": "s_win_out",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "A man in a shop fleece is looking at you across the yard. He isn't surprised. He's got his phone out, and he hasn't decided who to ring yet.",
          "choices": [
            {
              "label": "Take him down",
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1
                }
              ],
              "result_text": "You go for him before he's finished deciding.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Talk it out",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "prophetsBreath",
                    "optional": true,
                    "label": "Prophet's Breath",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You tell him you're with the landlord. The details matter less than how bored you sound. He puts the phone away.",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "He's heard that one before. He shouts for the others.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b29"
                }
              }
            },
            {
              "label": "Duck out of sight",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "You get behind the bins and wait. He looks for a while, then decides he imagined you.",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "He doesn't look away. He walks towards the bins, shouting.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b29"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b25"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b25"
      }
    },
    "b25": {
      "title": "From card 25",
      "cards": [
        {
          "key": "s_win_out2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Something you brought, or the road home.",
          "choices": [
            {
              "label": "Pan's Rapture",
              "requires": {
                "item": "pansRapture",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "pansRapture",
                  "optional": true,
                  "label": "Pan's Rapture",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "add": -1
                },
                {
                  "op": "reduce_raid_guards",
                  "count": 1
                }
              ],
              "result_text": "He forgets about you, and about his phone, and stands smiling at the bins.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Blast him",
              "requires": {
                "item": "blast",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "atLeast": 2
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1,
                  "situational": [
                    {
                      "if": {
                        "cash": {
                          "atLeast": 0
                        }
                      },
                      "enemyStartsHurt": 0.5
                    }
                  ]
                }
              ],
              "result_text": "One bang in a small yard. He goes down, and the windows along the back of the street light up.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Run for it",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b26"
      }
    },
    "b26": {
      "title": "From card 26",
      "cards": [
        {
          "key": "s_win_in",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "A man in the stockroom has seen you. He puts his box down carefully, like he'll need both hands.",
          "choices": [
            {
              "label": "Take him down",
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1
                }
              ],
              "result_text": "You close the distance before he's straightened up.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Talk it out",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "prophetsBreath",
                    "optional": true,
                    "label": "Prophet's Breath",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You tell him the manager sent you back for bags. He's never met the manager either. He lets it go.",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "He doesn't buy it. He calls through to the others.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b31"
                }
              }
            },
            {
              "label": "Duck out of sight",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "You're behind the cages before he's straightened up. He stares at the gap where you were, then picks up his box.",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "He sees where you went, and calls through to the others.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b31"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b27"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b27"
      }
    },
    "b27": {
      "title": "From card 27",
      "cards": [
        {
          "key": "s_win_in2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Something you brought, or the road home.",
          "choices": [
            {
              "label": "Pan's Rapture",
              "requires": {
                "item": "pansRapture",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "pansRapture",
                  "optional": true,
                  "label": "Pan's Rapture",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "add": -1
                },
                {
                  "op": "reduce_raid_guards",
                  "count": 1
                }
              ],
              "result_text": "He sits down on a pallet of water, smiling, and forgets why he stood up.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Blast him",
              "requires": {
                "item": "blast",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "atLeast": 2
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1,
                  "situational": [
                    {
                      "if": {
                        "cash": {
                          "atLeast": 0
                        }
                      },
                      "enemyStartsHurt": 0.5
                    }
                  ]
                }
              ],
              "result_text": "One bang among the shelving. He goes down, and so does a cage of crisps.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Run for it",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b28"
      }
    },
    "b28": {
      "title": "From card 28",
      "cards": [
        {
          "key": "s_win_wit",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Someone's seen you who isn't paid to stop you. They can't fight you, and you can't fight them. But they can tell someone, and on a street like this, someone is always listening.",
          "choices": [
            {
              "label": "Talk it out",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "prophetsBreath",
                    "optional": true,
                    "label": "Prophet's Breath",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You give them a reason boring enough to believe. They decide you're not their problem and go back to their evening.",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "They don't buy it. They're already dialling, and they're not dialling a friend.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b29"
                }
              }
            },
            {
              "label": "Duck out of sight",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "You step out of their line of sight and stay out of it until they decide they imagined you.",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "They follow you with their eyes, then with their phone.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b29"
                }
              }
            },
            {
              "label": "Run for it",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b29"
      }
    },
    "b29": {
      "title": "From card 29",
      "cards": [
        {
          "key": "s_alarm",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The shop's awake. Daniela is on the phone, customers are leaving without their shopping, and the men in fleeces are searching the building. If they find you now, they find you in front of everyone.",
          "choices": [
            {
              "label": "Hide",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You fold yourself in behind a stack of crates. They walk past twice and don't look down.",
                "effects": [],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "They find you behind the crates.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              }
            },
            {
              "label": "Bluff them",
              "check": {
                "base": 0.15,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.15,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "You point at the yard door and say he went that way. They half believe you, and half is enough.",
                "effects": [],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "They know every face that belongs in this shop, and yours isn't one of them.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              }
            },
            {
              "label": "Pan's Rapture",
              "requires": {
                "item": "pansRapture",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "pansRapture",
                  "optional": true,
                  "label": "Pan's Rapture",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "add": -1
                },
                {
                  "op": "reduce_raid_guards",
                  "count": 9
                }
              ],
              "result_text": "The search goes soft. The men in fleeces stand about in the aisle, smiling at the crisps.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b30"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b30"
      }
    },
    "b30": {
      "title": "From card 30",
      "cards": [
        {
          "key": "s_alarm2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Or scare them off, or leave while you still can.",
          "choices": [
            {
              "label": "Panic",
              "requires": {
                "item": "panic",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "panic",
                  "optional": true,
                  "label": "Panic",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "reduce_raid_guards",
                  "count": 2
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "They go without a word, and the shop barely notices."
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                }
              ],
              "result_text": "Two of them go white and run out through the yard door.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Run for it",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b31"
      }
    },
    "b31": {
      "title": "From card 31",
      "cards": [
        {
          "key": "post",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The stockroom isn't empty. Men in shop fleeces are stacking a shelf that's already full. They work for whoever owns the cellar, not the shop, and they're between you and the cellar door.",
          "choices": [
            {
              "label": "Fight",
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards"
                }
              ],
              "result_text": "They stop pretending to stack shelves.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Bluff past",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "alert": {
                      "atLeast": 2
                    },
                    "add": -0.3,
                    "label": "Hostile"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You tell them you've been sent down to check the cellar. Nobody wants to be the one who stopped the wrong person. They let you by.",
                "effects": [],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "One of them asks who sent you. There's no good answer, and his box goes down on the floor.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  },
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b32"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b32"
      }
    },
    "b32": {
      "title": "From card 32",
      "cards": [
        {
          "key": "post2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Something you brought.",
          "choices": [
            {
              "label": "Prophet's Breath: skip the post",
              "requires": {
                "item": "prophetsBreath",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "prophetsBreath",
                  "optional": true,
                  "label": "Prophet's Breath",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [],
              "result_text": "You know where each of them will be in the next ten seconds, and you're never there.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Time Pearl: freeze and rush past",
              "requires": {
                "item": "timePearl",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "timePearl",
                  "optional": true,
                  "label": "Time Pearl",
                  "effect": {
                    "kind": "unlock",
                    "nextCheck": {
                      "add": -0.15,
                      "label": "Rushed past the freeze"
                    }
                  }
                }
              ],
              "effects": [],
              "result_text": "The stockroom stops: a man mid-lift, a box in mid-air. You walk through it and reach the cellar door breathing hard.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Time Pearl: freeze the line guard",
              "requires": {
                "item": "timePearl",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "timePearl",
                  "optional": true,
                  "label": "Time Pearl",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1,
                  "situational": [
                    {
                      "if": {
                        "cash": {
                          "atLeast": 0
                        }
                      },
                      "firstStrike": true
                    }
                  ]
                }
              ],
              "result_text": "The one nearest the cellar door stops mid-sentence. The others don't.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "More…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b33"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b33"
      }
    },
    "b33": {
      "title": "From card 33",
      "cards": [
        {
          "key": "post3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Something that makes a post forget what it's for.",
          "choices": [
            {
              "label": "Pandemonium",
              "requires": {
                "all": [
                  {
                    "item": "pandemonium",
                    "optional": true
                  },
                  {
                    "security": {
                      "feature": "guards",
                      "atLeast": 2
                    }
                  }
                ],
                "display": "disable"
              },
              "items": [
                {
                  "item": "pandemonium",
                  "optional": true,
                  "label": "Pandemonium",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "atLeast": 2
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "situational": [
                    {
                      "if": {
                        "cash": {
                          "atLeast": 0
                        }
                      },
                      "enemyAnger": {
                        "tier": 1,
                        "fury": true
                      },
                      "enemyStartsHurt": 0.4
                    }
                  ]
                }
              ],
              "result_text": "A word in the wrong ear, and they turn on each other, shouting about whose fault you are.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Panic",
              "requires": {
                "item": "panic",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "panic",
                  "optional": true,
                  "label": "Panic",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "reduce_raid_guards",
                  "count": 2
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "They go without a word, and the shop barely notices."
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                }
              ],
              "result_text": "Two of them go white and leave through the yard door without their coats.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Pan's Rapture",
              "requires": {
                "all": [
                  {
                    "item": "pansRapture",
                    "optional": true
                  },
                  {
                    "alert": {
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "items": [
                {
                  "item": "pansRapture",
                  "optional": true,
                  "label": "Pan's Rapture",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "alert",
                  "add": -1
                },
                {
                  "op": "reduce_raid_guards",
                  "count": 9
                }
              ],
              "result_text": "They go soft around the eyes and sit down on the stock. One of them offers you a crisp.",
              "goto": {
                "branch": "b48"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b34"
      }
    },
    "b34": {
      "title": "From card 34",
      "cards": [
        {
          "key": "s_reinf",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The shop door chimes, and keeps chiming. More of the owner's people are coming in the front, past the customers going out.",
          "choices": [
            {
              "label": "Keep moving",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": false
                }
              ],
              "result_text": null,
              "goto": {
                "branch": "b49"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b35"
      }
    },
    "b35": {
      "title": "From card 35",
      "cards": [
        {
          "key": "s_cam",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Over the till, a camera on a bracket pans slowly across the queue. There's a screen in the back somewhere. If it gets a good look at you heading for the staff door, someone will come out to see who you are.",
          "choices": [
            {
              "label": "Time the sweep",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.58,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You count the pan and move on the turn. When it comes back, you're a customer looking at crisps.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "The camera turns back early and stops on you. On a screen somewhere in the back, you're the only thing moving.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b37"
                }
              }
            },
            {
              "label": "Stay in its blind spot",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.58,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "There's a stripe of floor beside the counter it never sees. You stay on it.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "The stripe is narrower than you thought. Your shoulder's on camera, and the rest of you follows.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b37"
                }
              }
            },
            {
              "label": "Hope it's on the blink",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "The lens flickers and the red light goes out, just long enough. Nobody's fixed it because nobody's noticed.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "It isn't on the blink. The red light stays on, and so does the recording.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b37"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": null,
              "goto": {
                "branch": "b36"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b36"
      }
    },
    "b36": {
      "title": "From card 36",
      "cards": [
        {
          "key": "s_cam2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "A camera is a system. It can't be talked round. It can only be stopped.",
          "choices": [
            {
              "label": "Time Pearl: freeze it",
              "requires": {
                "item": "timePearl",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "timePearl",
                  "optional": true,
                  "label": "Time Pearl",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": "The camera stops mid-pan. You walk under it, and it starts again on an empty queue.",
              "goto": {
                "branch": "b5"
              }
            },
            {
              "label": "Blast it",
              "requires": {
                "item": "blast",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "Out front, a lorry goes by at the same moment. People look at the road, not the ceiling."
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                }
              ],
              "result_text": "The camera comes off its bracket in pieces. The queue ducks.",
              "goto": {
                "branch": "b5"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b37"
      }
    },
    "b37": {
      "title": "From card 37",
      "cards": [
        {
          "key": "s_win_cam",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The camera's had a good look at you. Somebody in the back is watching the screen by now, and they're coming out to look in person.",
          "choices": [
            {
              "label": "Take him down",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1
                }
              ],
              "result_text": "He comes through the staff door expecting a shoplifter. You're ready for him.",
              "goto": {
                "branch": "b5"
              }
            },
            {
              "label": "Duck out of sight",
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ],
                "entry": "physical"
              },
              "success": {
                "result_text": "By the time he's out, you're behind the fridges. He looks along the aisles and goes back to his screen.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "He's out quicker than you expected and walks straight to where you're standing.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "sAt_till",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_back",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_stairs",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_yard",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_door",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_flap",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_cellar",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "sAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Blast him",
              "requires": {
                "item": "blast",
                "optional": true,
                "display": "disable"
              },
              "items": [
                {
                  "item": "blast",
                  "optional": true,
                  "label": "Blast",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ],
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2
                },
                {
                  "op": "set_flag",
                  "flag": "sReinfOpen",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1,
                  "situational": [
                    {
                      "if": {
                        "cash": {
                          "atLeast": 0
                        }
                      },
                      "enemyStartsHurt": 0.5
                    }
                  ]
                }
              ],
              "result_text": "One bang by the till. He goes down, and the queue goes out the door.",
              "goto": {
                "branch": "b5"
              }
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": false
                }
              ],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b38"
      }
    },
    "b38": {
      "title": "From card 38",
      "cards": [
        {
          "key": "s_ward",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "There's a ward on the cellar stairs. The air on the top step feels held, like a breath. Walk through it as you are and it goes off, and whoever set it will know.",
          "choices": [
            {
              "label": "Step through",
              "effects": [
                {
                  "op": "ward_trigger"
                }
              ],
              "result_text": "You step through. The air rings once, like a struck glass, and upstairs the radio goes quiet.",
              "goto": {
                "branch": "b41"
              }
            },
            {
              "label": "Slip it",
              "requires": {
                "observed": {
                  "id": "raid",
                  "ore": "fate",
                  "atLeast": 1
                },
                "display": "disable"
              },
              "check": {
                "base": 0.58,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.13,
                    "label": "A sharp read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A time read"
                  }
                ]
              },
              "success": {
                "result_text": "You find the thin place in it and go through sideways.",
                "effects": [],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "Halfway through, it notices you. The air rings.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              }
            },
            {
              "label": "Throw a decoy",
              "check": {
                "base": 0.55,
                "mods": []
              },
              "success": {
                "result_text": "You roll a tin of beans down the steps. The ward takes it. You wait out the ringing, then follow.",
                "effects": [],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "The ward lets the tin roll past and waits for you.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b39"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b39"
      }
    },
    "b39": {
      "title": "From card 39",
      "cards": [
        {
          "key": "s_ward2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Something you brought, or someone else to go first.",
          "choices": [
            {
              "label": "Trick a guard into it",
              "requires": {
                "all": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 1
                    }
                  },
                  {
                    "security": {
                      "feature": "guards",
                      "atLeast": 1
                    }
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "You tell a guard you heard something on the stairs. He goes to look and the ward takes him. You step round him.",
                "effects": [
                  {
                    "op": "reduce_raid_guards",
                    "count": 1
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "He isn't going down those stairs first, not for you. The ward gets you instead.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              }
            },
            {
              "label": "Powder past it",
              "requires": {
                "item": "enhancementPowder",
                "optional": true,
                "display": "disable"
              },
              "effects": [
                {
                  "op": "ward_trigger"
                }
              ],
              "result_text": "You go through it as fast as the powder will take you.",
              "goto": {
                "branch": "b41"
              },
              "items": [
                {
                  "item": "enhancementPowder",
                  "optional": true,
                  "label": "Enhancement Powder",
                  "effect": {
                    "kind": "wardPass",
                    "nextCheck": {
                      "add": 0.15,
                      "label": "Powder"
                    }
                  }
                }
              ]
            },
            {
              "label": "Open a Wormhole past it",
              "requires": {
                "all": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    }
                  },
                  {
                    "item": "wormhole",
                    "optional": true
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.85,
                "mods": [
                  {
                    "item": "wormhole",
                    "optional": true,
                    "label": "Wormhole",
                    "effect": {
                      "kind": "unlock"
                    }
                  }
                ]
              },
              "success": {
                "result_text": "You fold the stairs and step out at the bottom. The ward is behind you, guarding nothing.",
                "effects": [],
                "goto": {
                  "branch": "b41"
                }
              },
              "fail": {
                "result_text": "The fold lands short, right on the top step.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b41"
                }
              }
            },
            {
              "label": "More…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b40"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b40"
      }
    },
    "b40": {
      "title": "From card 40",
      "cards": [
        {
          "key": "s_ward3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "A ward is a system. Systems can be stopped.",
          "choices": [
            {
              "label": "Time Pearl: freeze the ward",
              "requires": {
                "item": "timePearl",
                "optional": true,
                "display": "disable"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": true
                }
              ],
              "result_text": "The ward stops mid-breath. You walk through it before it starts again.",
              "goto": {
                "branch": "b41"
              },
              "items": [
                {
                  "item": "timePearl",
                  "optional": true,
                  "label": "Time Pearl",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ]
            },
            {
              "label": "Back out…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b41"
      }
    },
    "b41": {
      "title": "From card 41",
      "cards": [
        {
          "key": "s_room",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The cellar: one bulb, old brick, barrels, and a vein humming in the floor you can feel through your shoes. Oh, and the guards now looking at you.",
          "choices": [
            {
              "label": "Fight for the room",
              "requires": {
                "security": {
                  "feature": "guards",
                  "atLeast": 1
                },
                "display": "hide"
              },
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards"
                }
              ],
              "result_text": "They don't give it up.",
              "goto": {
                "branch": "b42"
              }
            },
            {
              "label": "Walk to the vein",
              "requires": {
                "security": {
                  "feature": "guards",
                  "atMost": 0
                },
                "display": "hide"
              },
              "effects": [],
              "result_text": "Nobody's posted down here. You walk across to the vein.",
              "goto": {
                "branch": "b42"
              }
            },
            {
              "label": "Bluff past",
              "requires": {
                "security": {
                  "feature": "guards",
                  "atLeast": 1
                },
                "display": "hide"
              },
              "check": {
                "base": 0.45,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  },
                  {
                    "alert": {
                      "atLeast": 2
                    },
                    "add": -0.3,
                    "label": "Hostile"
                  },
                  {
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "You say you've been sent to take a reading. They've been down here long enough to want it to be true.",
                "effects": [],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "One of them asks who sent you. You haven't got a name ready.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "sReinfOpen",
                    "value": true
                  },
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              }
            },
            {
              "label": "Prophet's Breath: slip past",
              "requires": {
                "item": "prophetsBreath",
                "optional": true,
                "display": "disable"
              },
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "sAt_till",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_back",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_stairs",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_yard",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_door",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_flap",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_cellar",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "sAt_room",
                  "value": true
                }
              ],
              "result_text": "You know where each of them will look, and you're never there.",
              "goto": {
                "branch": "b42"
              },
              "items": [
                {
                  "item": "prophetsBreath",
                  "optional": true,
                  "label": "Prophet's Breath",
                  "effect": {
                    "kind": "unlock"
                  }
                }
              ]
            }
          ]
        }
      ],
      "then": {
        "branch": "b42"
      }
    },
    "b42": {
      "title": "From card 42",
      "cards": [
        {
          "key": "s_claim_route",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "You kneel on the vein. It's warm, like a pipe. Over your head, faintly, the till drawer opens and shuts."
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "alert": {
                  "atLeast": 2
                }
              },
              {
                "security": {
                  "feature": "alarm",
                  "atLeast": 1
                }
              },
              {
                "reinforcements": false
              }
            ]
          },
          "branch": "b43"
        },
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b45"
        },
        {
          "branch": "b44"
        }
      ]
    },
    "b43": {
      "title": "From card 43",
      "cards": [
        {
          "key": "s_final",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Upstairs, the shop door chimes and keeps chiming: the owner's people, coming in past the customers going out. They'll be on the cellar stairs in a minute.",
          "choices": [
            {
              "label": "Reach for the vein",
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards"
                }
              ],
              "result_text": "You reach for it anyway, with feet on the stairs.",
              "goto": {
                "branch": "b45"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b44"
      }
    },
    "b44": {
      "title": "From card 44",
      "cards": [
        {
          "key": "s_claim",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "This is what you came for. Claim it and it's yours, and the people who had it will know who took it. Loot it and you leave with what you can carry. If nobody saw you, nobody knows.",
          "choices": [
            {
              "label": "Claim it",
              "effects": [
                {
                  "op": "claim_raid_vein"
                }
              ],
              "result_text": "You take it outright. Word gets round fast — it always does — and the relationship with whoever ran this patch takes the hit that comes with being seen to do it."
            },
            {
              "label": "Loot and leave",
              "effects": [
                {
                  "op": "loot_raid_vein"
                }
              ],
              "result_text": "You take what you can carry and leave the rest where it stands. Someone else's problem, still."
            }
          ]
        }
      ],
      "then": "end"
    },
    "b45": {
      "title": "From card 45",
      "cards": [
        {
          "key": "s_claim_a",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Upstairs, the shop has stopped pretending. Claim it and it's yours, and the people who had it will know who took it. Loot it and at least you'll be carrying something when you run.",
          "choices": [
            {
              "label": "Claim it",
              "effects": [
                {
                  "op": "claim_raid_vein"
                }
              ],
              "result_text": "You take it outright. Word gets round fast — it always does — and the relationship with whoever ran this patch takes the hit that comes with being seen to do it.",
              "goto": {
                "branch": "b46"
              }
            },
            {
              "label": "Loot and leave",
              "effects": [
                {
                  "op": "loot_raid_vein"
                }
              ],
              "result_text": "You take what you can carry and leave the rest where it stands. Someone else's problem, still.",
              "goto": {
                "branch": "b46"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b46"
      }
    },
    "b46": {
      "title": "From card 46",
      "cards": [
        {
          "key": "s_getaway",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The way you came is full of people looking for you. There's the yard, if you're quick. There's the shop floor, where a customer is just a customer.",
          "choices": [
            {
              "label": "Run",
              "check": {
                "base": 0.6,
                "entry": "physical",
                "mods": [
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  }
                ]
              },
              "success": {
                "result_text": "Out the yard door, over the bins, down the side passage. Nobody catches you.",
                "effects": []
              },
              "fail": {
                "result_text": "They're waiting in the yard.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ]
              }
            },
            {
              "label": "Out through the shop",
              "check": {
                "base": 0.6,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 1
                    },
                    "add": 0.05,
                    "label": "A read"
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.05,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "You come up through the stockroom and out past the till. Daniela sees you, then looks at the clock instead. Eleven minutes till the end of her shift.",
                "effects": []
              },
              "fail": {
                "result_text": "Halfway down the aisle, a man in a shop fleece steps out from behind the crisps and blocks the door.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ]
              }
            },
            {
              "label": "Open a Wormhole",
              "requires": {
                "all": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    }
                  },
                  {
                    "item": "wormhole",
                    "optional": true
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.85,
                "mods": [
                  {
                    "item": "wormhole",
                    "optional": true,
                    "label": "Wormhole",
                    "effect": {
                      "kind": "unlock"
                    }
                  }
                ]
              },
              "success": {
                "result_text": "The fold takes you out of the cellar and sets you down two streets away.",
                "effects": []
              },
              "fail": {
                "result_text": "The fold lands short, at the top of the cellar stairs.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ]
              }
            }
          ]
        }
      ],
      "then": "end"
    },
    "b47": {
      "title": "From card 47",
      "cards": [
        {
          "key": "s_retreat",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The street's right there. Leave before anyone's noticed you and the shop never knows. Leave after, and they'll be watching for you for days.",
          "choices": [
            {
              "label": "Back out",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "effects": [
                {
                  "op": "back_out"
                }
              ],
              "result_text": "You leave like a customer who couldn't find what they wanted.",
              "goto": {
                "branch": "b53"
              }
            },
            {
              "label": "Run for it",
              "requires": {
                "alert": {
                  "atLeast": 2
                },
                "display": "hide"
              },
              "check": {
                "base": 0.6,
                "entry": "physical",
                "mods": [
                  {
                    "item": "enhancementPowder",
                    "optional": true,
                    "label": "Enhancement Powder",
                    "effect": {
                      "kind": "bonus",
                      "add": 0.15,
                      "entry": "physical"
                    }
                  }
                ]
              },
              "success": {
                "result_text": "You go out the quickest way and keep going. Behind you, someone's shouting a description that could be anybody.",
                "effects": [
                  {
                    "op": "back_out"
                  }
                ],
                "goto": {
                  "branch": "b53"
                }
              },
              "fail": {
                "result_text": "They cut you off between the shelves.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              }
            },
            {
              "label": "Open a Wormhole out",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atLeast": 2
                    }
                  },
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    }
                  },
                  {
                    "item": "wormhole",
                    "optional": true
                  }
                ],
                "display": "disable"
              },
              "check": {
                "base": 0.85,
                "mods": [
                  {
                    "item": "wormhole",
                    "optional": true,
                    "label": "Wormhole",
                    "effect": {
                      "kind": "unlock"
                    }
                  }
                ]
              },
              "success": {
                "result_text": "The fold sets you down on a pavement a street away, next to a bin.",
                "effects": [
                  {
                    "op": "back_out"
                  }
                ],
                "goto": {
                  "branch": "b53"
                }
              },
              "fail": {
                "result_text": "The fold lands short, in the middle of the shop floor, in front of everyone.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards",
                    "situational": [
                      {
                        "if": {
                          "cash": {
                            "atLeast": 0
                          }
                        },
                        "enemyFirstStrike": true
                      }
                    ]
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              }
            },
            {
              "label": "Carry on",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b48"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b48"
      }
    },
    "b48": {
      "title": "From card 48",
      "cards": [
        {
          "key": "s_resume",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "You give it a count of ten, and listen."
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "reinforcements": true
              },
              {
                "flag": "sReinfOpen"
              }
            ]
          },
          "branch": "b34"
        },
        {
          "branch": "b49"
        }
      ]
    },
    "b49": {
      "title": "From card 49",
      "cards": [
        {
          "key": "s_resume2",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "Then you get on with it."
        }
      ],
      "then": [
        {
          "if": {
            "flag": "sAt_till"
          },
          "branch": "b5"
        },
        {
          "if": {
            "flag": "sAt_back"
          },
          "branch": "b51"
        },
        {
          "if": {
            "flag": "sAt_stairs"
          },
          "branch": "b52"
        },
        {
          "if": {
            "flag": "sAt_yard"
          },
          "branch": "b11"
        },
        {
          "if": {
            "flag": "sAt_door"
          },
          "branch": "b13"
        },
        {
          "if": {
            "flag": "sAt_flap"
          },
          "branch": "b15"
        },
        {
          "if": {
            "flag": "sAt_cellar"
          },
          "branch": "b17"
        },
        {
          "branch": "b41"
        }
      ]
    },
    "b50": {
      "title": "From card 50",
      "cards": [
        {
          "key": "s_back_loud",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "You're in the stockroom, and the yard door behind you is open to the night. Either nobody heard, or everybody did."
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "alert": {
                  "atLeast": 2
                }
              },
              {
                "security": {
                  "feature": "guards",
                  "atLeast": 1
                }
              }
            ]
          },
          "branch": "b31"
        },
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b29"
        },
        {
          "branch": "b51"
        }
      ]
    },
    "b51": {
      "title": "From card 51",
      "cards": [
        {
          "key": "s_back_in",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "The stockroom: cages of crisps, a pallet of water, a mop in a bucket. The cellar door is at the far end. Between you and it is whoever's back here."
        }
      ],
      "then": [
        {
          "if": {
            "security": {
              "feature": "guards",
              "atLeast": 1
            }
          },
          "branch": "b31"
        },
        {
          "branch": "b7"
        }
      ]
    },
    "b52": {
      "title": "From card 52",
      "cards": [
        {
          "key": "s_stairs_in",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "The cellar door is behind a stack of empty crates. Warm air comes through the gap underneath it, and a hum you can feel in the floor. That's the vein."
        }
      ],
      "then": [
        {
          "if": {
            "security": {
              "feature": "ward",
              "atLeast": 1
            }
          },
          "branch": "b38"
        },
        {
          "branch": "b9"
        }
      ]
    },
    "b53": {
      "title": "From card 53",
      "cards": [
        {
          "key": "s_out",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "Outside, the bus stop queue hasn't moved and nobody's looking at you. The vein is still under the shop. It'll be there next time, and so will they."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "repeatable",
      "reinforceClock",
      "fightPresets",
      "observations",
      "cards",
      "on_complete"
    ],
    "cards": {
      "s_intro": [
        "key",
        "type",
        "label",
        "speaker",
        "observe",
        "text"
      ],
      "s_front": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_front2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_in_cust": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_till": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_till2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_back": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_back2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_lock": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_lock2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_yard": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_yard2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_door": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_door2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_flap": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_flap2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_cellar": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_cellar2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_seen_till": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_seen_flap": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_seen_yard": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_seen_door": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_seen_in": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_win_out": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_win_out2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_win_in": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_win_in2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_win_wit": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_alarm": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_alarm2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "post": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "post2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "post3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_reinf": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_cam": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_cam2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_win_cam": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_ward": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_ward2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_ward3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_room": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_claim_route": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_final": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_claim": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "end",
        "choices"
      ],
      "s_claim_a": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_getaway": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "end",
        "choices"
      ],
      "s_retreat": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "s_resume": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_resume2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_back_loud": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_back_in": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_stairs_in": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "s_out": [
        "key",
        "type",
        "label",
        "speaker",
        "end",
        "text"
      ]
    }
  },
  "_keyLinks": true,
  "_liveSource": "raid_shop.json",
  "_liveHash": "68538638"
}
```

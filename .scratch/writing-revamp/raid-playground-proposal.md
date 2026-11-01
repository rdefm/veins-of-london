# raid_playground

```json
{
  "id": "raid_playground",
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "narration",
          "text": "Recap text of location. Image is the satellite view with he 3 approaches tagged. Image and text state that the vein is under a shrubbery between the nursery playground and he church hall. Observations are focused around the general area. Image file assets in C:\\Users\\Richard\\projects\\veins-of-london\\.scratch\\playground_raid",
          "choices": [
            {
              "id": "option1",
              "label": "Church",
              "result_text": "",
              "goto": {
                "branch": "church_approach"
              }
            },
            {
              "id": "option2",
              "label": "Hall",
              "result_text": "",
              "goto": {
                "branch": "hall_approach"
              }
            },
            {
              "id": "option3",
              "label": "Playground",
              "result_text": "",
              "goto": {
                "branch": "playground_approach"
              }
            }
          ]
        }
      ]
    },
    "church_approach": {
      "title": "church",
      "cards": [
        {
          "key": "c3",
          "type": "narration",
          "text": "No guards, but caretaker (Roger) is cleaning and may spot/challenge player if they try to go from church to playground. Player can find a way through to the vein via a backdoor. Observation gives hints as to which door (chance to see a floorplan which helps, dirt/mud on ground beside the right door that leads outside).\nPlayer can try to force door (blast or otherwise), or convince caretaker to let them outside (if so he comments on the Shrubbery and tells you not to mess with it, he's been working on it for years)."
        }
      ]
    },
    "hall_approach": {
      "title": "hall",
      "cards": [
        {
          "key": "c2",
          "type": "narration",
          "text": "Door lock has a code; prophets breath lets player figure it out otherwise low % chance. Observation; through the window can see a noticeboard with the code on it.\nImage: C:\\Users\\Richard\\projects\\veins-of-london\\.scratch\\playground_raid\\hall_approach.png (needs editing to match game visual style)",
          "choices": [
            {
              "label": "Guess the door code",
              "id": "option1",
              "effects": [],
              "check": {
                "base": 0.05,
                "mods": [
                  {
                    "observed": {
                      "id": "hall_approach",
                      "ore": "physics",
                      "atLeast": 1
                    },
                    "add": 0.5,
                    "label": ""
                  }
                ]
              },
              "success": {
                "result_text": "",
                "effects": [],
                "goto": {
                  "branch": "hall_inside"
                }
              },
              "fail": {
                "result_text": null,
                "effects": []
              }
            },
            {
              "label": "Force the door",
              "id": "option2",
              "check": {
                "base": 0.5,
                "mods": []
              },
              "success": {
                "result_text": "",
                "effects": [],
                "goto": {
                  "branch": "hall_inside"
                }
              },
              "fail": {
                "result_text": "This door won't budge, and now your shoulder hurts. Back to square 1.",
                "effects": [],
                "goto": {
                  "branch": "main"
                }
              }
            },
            {
              "id": "option3",
              "label": "Enter the door code",
              "pick": {
                "observation": "hall_approach",
                "ores": {
                  "physics": [
                    {
                      "atLeast": 1,
                      "result_text": "",
                      "effects": [],
                      "goto": {
                        "branch": "hall_inside"
                      }
                    }
                  ]
                }
              },
              "requires": {
                "observed": {
                  "id": "hall_approach",
                  "ore": "physics",
                  "atLeast": 2
                },
                "display": "disable",
                "reason": "You don't know the code"
              }
            }
          ],
          "observe": "hall_approach"
        }
      ]
    },
    "playground_approach": {
      "title": "playground",
      "cards": [
        {
          "key": "c4",
          "type": "narration",
          "text": "Door is locked, no code. Can jump the fence to get to the playground.",
          "choices": [
            {
              "id": "option1",
              "label": "Force the gate open",
              "result_text": ""
            },
            {
              "id": "option2",
              "label": "Jump the fence",
              "result_text": ""
            },
            {
              "id": "option3",
              "label": "Go back and try another approach",
              "result_text": "",
              "goto": {
                "branch": "main"
              }
            }
          ],
          "observe": null
        }
      ]
    },
    "hall_inside": {
      "title": "hall_inside",
      "cards": [
        {
          "key": "c5",
          "type": "narration",
          "text": "Once inside hall, can see shrubbery with vein underneath.\n\nCan try to get window open to sneak through, or break window.\nVery low observation roll tells player which door leads there from church; option to go via the church and find your way through.\n\nShrubbery description: Monty Python reference.\n",
          "choices": [
            {
              "id": "option1",
              "label": "Try to open the window",
              "result_text": "",
              "goto": {
                "branch": "shrubbery"
              }
            },
            {
              "id": "option2",
              "label": "Break the window",
              "result_text": "",
              "goto": {
                "branch": "shrubbery"
              }
            },
            {
              "id": "option3",
              "label": "Go back and try another approach",
              "result_text": "",
              "goto": {
                "branch": "main"
              }
            }
          ]
        }
      ]
    },
    "shrubbery": {
      "title": "shrubbery",
      "cards": [
        {
          "key": "c6",
          "type": "narration",
          "text": "Player is at the vein. There's a camera that can be noticed. If it's triggered, silent alarm triggers, guards come in 2 turns.\n\nCamera can be observed with physics roll. Options to deal with it:\n - Hope it's broken (low roll, but very high if Be A Lady is present)\n - Trace the wires, realise its controlled from a room in the church, go back to the church to disable the camera\n - Just go anyway (alarm triggers, and guards arrive before player can harvest the vein.\n - Destroy the camera (normal roll, can also use blast for guaranteed success). Silent alarm  they triggers, player has 2 turns until they arrive. When leaving the vein they fight the player, if player can't talk their way past them. If player claims vein, encounter is different where they either fight, or tell guards that player now owns this vein and the guards back down.\n\n",
          "choices": [
            {
              "label": "Hope the camera is broken",
              "id": "option1",
              "check": {
                "base": 0.05,
                "mods": []
              },
              "success": {
                "result_text": "",
                "effects": [],
                "goto": {
                  "branch": "vein_not_seen"
                }
              },
              "fail": {
                "result_text": null,
                "effects": [],
                "goto": {
                  "branch": "vein_seen"
                }
              }
            },
            {
              "label": "Break the camera",
              "id": "option2",
              "check": {
                "base": 0.5,
                "mods": []
              },
              "success": {
                "result_text": "",
                "effects": []
              },
              "fail": {
                "result_text": null,
                "effects": []
              }
            },
            {
              "id": "option3",
              "label": "Ignore the camera, just get to the vein",
              "result_text": ""
            }
          ]
        }
      ]
    },
    "vein_not_seen": {
      "title": "vein_not_seen",
      "cards": [
        {
          "key": "c7",
          "type": "narration",
          "text": "Player has option to harvest the vein, or claim it, as when a normal raid ends."
        }
      ]
    },
    "vein_seen": {
      "title": "vein_seen",
      "cards": [
        {
          "key": "c8",
          "type": "narration",
          "text": "Player has option to harvest the vein, or claim it, as when a normal raid ends.",
          "choices": [
            {
              "id": "option1",
              "label": "Harvest the vein and leave",
              "result_text": "",
              "goto": {
                "branch": "harvested_seen"
              }
            },
            {
              "id": "option2",
              "label": "Claim the vein",
              "result_text": "",
              "goto": {
                "branch": "claimed_vein_seen"
              }
            }
          ]
        }
      ]
    },
    "harvested_seen": {
      "title": "harvested_seen",
      "cards": [
        {
          "key": "c9",
          "type": "narration",
          "text": "Player sees 2 guards turn up, and head in the player's direction. Player can fight or try to talk their way out of it. High observation roll means player spots them first and can escape unseen"
        }
      ]
    },
    "claimed_vein_seen": {
      "title": "claimed_vein_seen",
      "cards": [
        {
          "key": "c10",
          "type": "narration",
          "text": "Player sees 2 guards turn up, and head in the player's direction. Player knows if they avoid them, the guards will just reclaim the vein, so must confront them.\n\nOptions to fight them, or convince them to back off and that player owns the vein now."
        }
      ]
    }
  },
  "observations": {
    "hall_approach": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Through the window you can see a noticeboard covered with leaflets and post-its. One says 'DOOR' and the numbers 7624"
            },
            {
              "base": 0.55,
              "text": "Through the window you can see a noticeboard covered with leaflets and post-its. One says 'DOOR' and some numbers; you can only make out some of the numbers"
            }
          ],
          "miss": "Through the window you see chairs, some folded tables, a noticeboard. Nothing useful here."
        }
      }
    }
  },
  "_comments": [
    {
      "id": "m1",
      "kind": "claude",
      "status": "open",
      "text": "Roll to force the door. Success more likely as Player's Body skill level is higher. I also want an option here to use a Blast item. A high success opens the door without being noticed. A medium success opens the door but raises alarm level. Low success does some damage to the player (-3 HP) and door doens't open. Using blast always raises alarm level",
      "anchor": {
        "card": "c2",
        "option": 1,
        "slot": "success"
      }
    },
    {
      "id": "m2",
      "kind": "claude",
      "status": "open",
      "text": "If a player uses Prophet's Breath, I want them to be able to figure out the door code, guaranteed",
      "anchor": {
        "card": "c2",
        "option": 0,
        "slot": "success"
      }
    },
    {
      "id": "m3",
      "kind": "claude",
      "status": "open",
      "text": "If player has Be A Lady activated, success chance for \"Hope the camera is broken\" should increase to 0.95",
      "anchor": {
        "card": "c6",
        "option": 0,
        "slot": "success"
      }
    }
  ],
  "_layout": {
    "c:c1": [
      -491,
      9
    ],
    "b:church_approach": [
      -43,
      -407
    ],
    "b:playground_approach": [
      -87,
      502
    ],
    "b:hall_approach": [
      -71,
      235
    ],
    "b:vein_not_seen": [
      1419,
      -24
    ],
    "b:vein_seen": [
      1420,
      165
    ],
    "b:harvested_seen": [
      1849,
      243
    ],
    "b:claimed_vein_seen": [
      1839,
      332
    ]
  }
}
```

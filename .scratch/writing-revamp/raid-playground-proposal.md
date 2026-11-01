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
          "text": "The old church has an adjacent hall, and a small nursery and playground. The vein is in a tiny garden courtyard between all 3 sites.\nObservations are focused around the general area. Image file assets in C:\\Users\\Richard\\projects\\veins-of-london\\.scratch\\playground_raid",
          "choices": [
            {
              "id": "option1",
              "label": "Try the church",
              "result_text": "",
              "goto": {
                "branch": "church_approach"
              }
            },
            {
              "id": "option2",
              "label": "Look for a way in via the hall",
              "result_text": "",
              "goto": {
                "branch": "hall_approach"
              }
            },
            {
              "id": "option3",
              "label": "Check out the playground",
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
          "text": "Inside the church is quiet and cold. There's a light scent of incense in the air. You see a caretaker sorting some prayer books.\n\n - Speak to the caretaker\nAdvantage if life insight 1\n - Try to find a door to the vein\nAdvantage with life insight 2, physics insight 2, time insight 2.\nLeads to trying to open the door.\n\n\nNo guards, but caretaker (Roger) is cleaning and may spot/challenge player if they try to go from church to playground. Player can find a way through to the vein via a backdoor. Observation gives hints as to which door (chance to see a floorplan which helps, dirt/mud on ground beside the right door that leads outside).\nPlayer can try to force door (blast or otherwise), or convince caretaker to let them outside (if so, he comments on the Shrubbery and tells you not to mess with it, he's been working on it for years).",
          "observe": "church",
          "choices": [
            {
              "id": "option1",
              "label": "Speak to the caretaker",
              "result_text": "",
              "goto": {
                "branch": "church_caretaker"
              }
            },
            {
              "label": "Try to find a door to the vein",
              "id": "option2",
              "check": {
                "base": 0.35,
                "mods": [
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.5,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.5,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.5,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 1
                    },
                    "add": 0.35,
                    "label": ""
                  }
                ]
              },
              "success": {
                "result_text": "",
                "effects": [],
                "goto": {
                  "branch": "church_vein_door"
                }
              },
              "fail": {
                "result_text": "You wander around the church, trying not to draw attention. After walking around longer than you'd care to admit, you are about to admit defeat when the caretaker approaches you.",
                "effects": [],
                "goto": {
                  "branch": "church_caretaker"
                }
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
          "text": "There is a tall wooden fence in front of the nursery playground. The gate is locked and barred from the other side.",
          "choices": [
            {
              "label": "Blast the gate open",
              "id": "option1",
              "effects": [],
              "result_text": "",
              "requires": {
                "item": ""
              },
              "goto": {
                "branch": "shrubbery"
              }
            },
            {
              "label": "Jump the fence",
              "id": "option2",
              "check": {
                "base": 0.5,
                "mods": []
              },
              "success": {
                "result_text": "You get a run up and grab the top of the fence, then pull yourself over to the other side.",
                "effects": [],
                "goto": {
                  "branch": "shrubbery"
                }
              },
              "fail": {
                "result_text": "You get a run up and jump, aiming for the top of the fence. You don't even get close, and barely avoid faceplanting into the fence.",
                "effects": []
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
                "result_text": "The camera is no longer recording. You head over to the vein.",
                "effects": [],
                "goto": {
                  "branch": "vein_not_seen"
                }
              },
              "fail": {
                "result_text": "You didn't manage to break the camera. You did, however, manage to stumble into the camera's line of sight. No point in stealth now; speed is your best option.",
                "effects": [],
                "goto": {
                  "branch": "vein_seen"
                }
              }
            },
            {
              "id": "option3",
              "label": "Ignore the camera, just get to the vein",
              "result_text": "",
              "goto": {
                "branch": "vein_seen"
              }
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
          "text": "Player has option to harvest the vein, or claim it, as when a normal raid ends.",
          "choices": [
            {
              "id": "option1",
              "label": "Harvest the vein and leave",
              "result_text": "",
              "goto": {
                "branch": "harvested_not_seen"
              }
            },
            {
              "id": "option2",
              "label": "Claim the vein",
              "result_text": "",
              "goto": {
                "branch": "claimed_vein_not_seen"
              }
            }
          ]
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
          "text": "Player sees 2 guards turn up, and head in the player's direction. Player can fight or try to talk their way out of it. \nHigh observation roll means player spots them first and can escape unseen",
          "observe": "harvested_seen",
          "choices": [
            {
              "label": "Try to avoid them",
              "id": "option1",
              "check": {
                "base": 0.25,
                "mods": [
                  {
                    "observed": {
                      "id": "harvested_seen",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.5,
                    "label": ""
                  }
                ]
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
              "id": "option2",
              "label": "Get ready for a fight",
              "result_text": "",
              "goto": {
                "branch": "fight_prep"
              }
            },
            {
              "label": "Try to talk your way out",
              "id": "option3",
              "check": {
                "base": 0.25,
                "mods": []
              },
              "success": {
                "result_text": "You act like you're from the church and talk to them about Jesus. They don't have time for time for a God botherer, and walk off quickly to the vein. You're free to go.",
                "effects": []
              },
              "fail": {
                "result_text": "You act like you're from the church and talk to them about Jesus. They ask your name. From their expression, you assume they didn't believe you when you said \"Father McChurch\".",
                "effects": []
              }
            }
          ]
        }
      ]
    },
    "claimed_vein_seen": {
      "title": "claimed_vein_seen",
      "cards": [
        {
          "key": "c10",
          "type": "narration",
          "text": "Player sees 2 guards turn up, and head in the player's direction. Player knows if they avoid them, the guards will just reclaim the vein, so must confront them.\n\nOptions to fight them, or convince them to back off and that player owns the vein now.\n - Fighting: high observation in Life tells you they are glancing around, unsure if you're the threat (or if you've got back up). High observation in emotion shows they're nervous, amped up, and jumpy.\nIf you strike quickly you'll get a head start. Starting a fight with either of these observations means player gets a free bonus action at the start of the fight.\n - Talk them down; either of the observations above gives an advantage. Successful text is player saying they can see the guys are nervous; they can walk away without any fighting. Tell their bosses that this vein belongs to someone else now. Failed roll has player saying the wrong thing and guards lash out, starting the fight.\n - Try to avoid them: same observations give advantage as player knows to not move or make sudden movements, and look like you belong. Examines a bush; guards walk past, player leaves.\n\n",
          "choices": [
            {
              "label": "Try to avoid them",
              "id": "option1",
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.3,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.3,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.3,
                    "label": ""
                  }
                ]
              },
              "success": {
                "result_text": "You move slowly but deliberately, like you belong. You examine the flower bed with a vague sense of annoyance, tutting about when they were last watered. The guards breeze past with barely a second glance.",
                "effects": []
              },
              "fail": {
                "result_text": "You sprint to some bushes to try and hide behind them, but the guards spot you. Now they're heading your way.",
                "effects": [],
                "goto": {
                  "branch": "fight_prep"
                }
              }
            },
            {
              "id": "option2",
              "label": "Get ready for a fight",
              "result_text": "",
              "goto": {
                "branch": "fight_prep"
              }
            },
            {
              "label": "Try to talk your way out",
              "id": "option3",
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.3,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "emotion",
                      "atLeast": 2
                    },
                    "add": 0.3,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.3,
                    "label": ""
                  }
                ]
              },
              "success": {
                "result_text": "Hands visible, you calmly tell them that everyone can walk away safe and sound if they tell their bosses that this vein belongs to someone else now. They glance at each other, then nod at you and back away.",
                "effects": []
              },
              "fail": {
                "result_text": "You wave energetically to get their attention. They jump, then head over to you, fists balled. So much for talking...",
                "effects": [],
                "goto": {
                  "branch": "fight_prep"
                }
              }
            }
          ]
        }
      ]
    },
    "claimed_vein_not_seen": {
      "title": "claimed_vein_not_seen",
      "cards": [
        {
          "key": "c11",
          "type": "narration",
          "text": "You see 2 men walking through the church grounds. Heavyset, attention focused on people, hiding posts, and entry points - guards on patrol, not actively expecting trouble."
        },
        {
          "key": "c14",
          "type": "narration",
          "text": "If you leave now, they'll just reclaim the vein. You need to send a clear message that this belongs to you now.\n\nOptions to fight them (you catch them unaware so get a free bonus action), or convince them to back off and that player owns the vein now.",
          "choices": [
            {
              "id": "option1",
              "label": "Fight them off",
              "result_text": "",
              "goto": {
                "branch": "fight_prep"
              }
            },
            {
              "label": "Tell them the vein belongs to you now",
              "id": "option2",
              "check": {
                "base": 0.5,
                "mods": [
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 22
                    },
                    "add": 0.4,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 1
                    },
                    "add": 0.4,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "physics",
                      "atLeast": 1
                    },
                    "add": 0.2,
                    "label": ""
                  },
                  {
                    "observed": {
                      "id": "",
                      "ore": "life",
                      "atLeast": 1
                    },
                    "add": 0.2,
                    "label": ""
                  }
                ]
              },
              "success": {
                "result_text": "You tell them vein is under new ownership, and they can leave safe and sound to tell their boss. They look you up and own, then glance around for any hidden backup you might have. Eventually they nod at you and leave.",
                "effects": []
              },
              "fail": {
                "result_text": "You tell them vein is under new ownership, and they should leave. They look you up and down, and seem to like their chances. Uh oh.",
                "effects": [],
                "goto": {
                  "branch": "fight_prep"
                }
              }
            }
          ],
          "observe": "claimed_vein_not_seen"
        }
      ]
    },
    "harvested_not_seen": {
      "title": "harvested_not_seen",
      "cards": [
        {
          "key": "c12",
          "type": "narration",
          "text": "You leave the church grounds, the stolen ore warm in the bag under your arm."
        }
      ]
    },
    "fight_prep": {
      "title": "fight_prep",
      "cards": [
        {
          "key": "c13",
          "type": "narration",
          "text": "You have moments before the fighting begins. If you have any last minute items you want to use before thing's kick off, now's the time."
        }
      ]
    },
    "church_vein_door": {
      "title": "church_vein_door",
      "cards": [
        {
          "key": "c15",
          "type": "narration",
          "text": "You can feel the vein just beyond this locked door. Now you just have to find a way to open it.",
          "choices": [
            {
              "label": "Force the door open",
              "id": "option1",
              "check": {
                "base": 0.5,
                "mods": []
              },
              "success": {
                "result_text": "The door shudders open as you bash it. You grab the handle before it bangs against the wall.",
                "effects": [],
                "goto": {
                  "branch": "shrubbery"
                }
              },
              "fail": {
                "result_text": "Your shoulder hurts, and the door is still there, smugly silent. It might be your wounded pride, wounded shoulder, or imagination, but you'd swear the door is mocking you.",
                "effects": []
              }
            },
            {
              "label": "Blast the door open",
              "id": "option2",
              "check": {
                "base": 1,
                "mods": []
              },
              "success": {
                "result_text": "To door swings on its hinges and slams loudly against the wall. It wasn't subtle, but it got the job done.",
                "effects": [],
                "goto": {
                  "branch": "shrubbery"
                }
              },
              "fail": {
                "result_text": null,
                "effects": []
              },
              "requires": {
                "item": ""
              }
            },
            {
              "id": "option3",
              "label": "Ask the caretaker to open it",
              "result_text": "",
              "goto": {
                "branch": "church_caretaker"
              }
            }
          ]
        }
      ]
    },
    "church_caretaker": {
      "title": "church_caretaker",
      "cards": [
        {
          "key": "c16",
          "type": "speaker",
          "text": "\"Hello there,\" he says with a smile. \"I'm Roger Schrubber, the caretaker. Can I help you?\"",
          "speaker": "Roger",
          "choices": [
            {
              "label": "Ask if he can open the door to the vein",
              "id": "option1",
              "check": {
                "base": 0.5,
                "mods": []
              },
              "success": {
                "result_text": "You say you're a council surveyor and need to check the integrity of the south wall. He looks at the pile of unsorted books and sighs. \"Come along then, I'll take you there.\"",
                "effects": [],
                "goto": {
                  "branch": "church_caretaker_to_shrubbery"
                }
              },
              "fail": {
                "result_text": "You say you're from the church society to view the southern wall. He eyes you suspiciously. \"Hm. It's this way. Let me call the management company on the way.\"",
                "effects": [],
                "goto": {
                  "branch": "church_caretaker_to_shrubbery"
                }
              }
            },
            {
              "id": "option2",
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
    "church_caretaker_to_shrubbery": {
      "title": "church_caretaker_to_shrubbery",
      "cards": [
        {
          "key": "c17",
          "type": "speaker",
          "text": "\"The south wall faces a lovely small garden, just next to the nursery playground,\" Roger says. \"Please don't touch the shrubbery; it requires a lot of caretaking.\"",
          "speaker": "Roger"
        }
      ],
      "then": {
        "branch": "shrubbery"
      }
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
    },
    "harvested_seen": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Two large men walking from the street to the vein. Their build, expressions, and speed tell you they're guards - but you've seen them first."
            },
            {
              "base": 0.55,
              "text": "Two large men walking from the street to the vein. Their build, expressions, and speed tell you they're guards."
            }
          ],
          "miss": "You see a few passers-by on the street and in the church yard."
        },
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Two men are walking purposefully, glancing around for threats, amped up for conflict. But they haven't spotted you yet."
            },
            {
              "base": 0.55,
              "text": "Two men are walking purposefully, glancing around for threats, amped up for conflict."
            }
          ],
          "miss": "They're walking quickly. Powerwalking? In desperate need of the loo?"
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "They're nervous, amped up, and jumpy. Any sudden movement or aggressive words could trigger conflictt."
            },
            {
              "base": 0.55,
              "text": "They're clearly alert and looking for trouble."
            }
          ],
          "miss": "They're looking for something. Jesus? Their car keys? Who knows."
        }
      }
    },
    "claimed_vein_not_seen": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Two large men walking from the street to the vein. Their build, expressions, and speed tell you they're guards - but you've seen them first."
            },
            {
              "base": 0.55,
              "text": "Two large men walking from the street to the vein. Their build, expressions, and speed tell you they're guards."
            }
          ],
          "miss": "You see a few passers-by on the street and in the church yard."
        },
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "Two men are walking purposefully, glancing around for threats, amped up for conflict. But they haven't spotted you yet."
            },
            {
              "base": 0.55,
              "text": "Two men are walking purposefully, glancing around for threats, amped up for conflict."
            }
          ],
          "miss": "They're walking quickly. Powerwalking? In desperate need of the loo?"
        }
      }
    },
    "church": {
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "You see a board with details for the fire escape route, including a map of the exits. It also shows where the door nearest to the vein is."
            },
            {
              "base": 0.55,
              "text": "There's a map near the main door showing fire exits. It also shows you where the door closest to the vein is."
            }
          ],
          "miss": "Pews with uncomfortable wooden benches. Stone flooring worn smooth from however many footsteps. A vague scent of 'old'. You've seen dozens of churches like this."
        },
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "A door to the south leads to a corridor with another door, traces of mud and dirt in front of it. Seems to lead outside."
            },
            {
              "base": 0.55,
              "text": "There aren't many people. The place seems relatively clean despite its size; the caretaker takes his job seriously."
            }
          ],
          "miss": "This place is a ghost town. Wait, if calc exists, could ghosts exist too? In this place, it doesn't seem so far fetched."
        },
        "time": {
          "tiers": [
            {
              "base": 0.25,
              "text": "The church walls look old but are 'only' Victorian. A plaque in the corner details that the original Saxon church was on the south side of the current building; maybe it's where the vein is."
            },
            {
              "base": 0.55,
              "text": "This building is recent (barely 100 years old), but this site has had a church since the Saxons."
            }
          ],
          "miss": "The books the caretaker is sorting look as old as he does."
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
    },
    {
      "id": "m4",
      "kind": "claude",
      "status": "open",
      "text": "option 1 from card c14: player should get a free bonus round when the fight starts",
      "anchor": {
        "card": "c14",
        "option": 0,
        "slot": "result"
      }
    },
    {
      "id": "m5",
      "kind": "claude",
      "status": "open",
      "text": "Option 2 on curch_vein_door; player must have Blast. This option consumes 1 blast and raises the alarm level",
      "anchor": {
        "card": "c15",
        "option": 1,
        "slot": "success"
      }
    },
    {
      "id": "m6",
      "kind": "claude",
      "status": "open",
      "text": "Failure for church_vein_door option 1 should reduce player's hp by 3",
      "anchor": {
        "card": "c15",
        "option": 0,
        "slot": "fail"
      }
    },
    {
      "id": "m7",
      "kind": "claude",
      "status": "open",
      "text": "Failure here should raise alarm level",
      "anchor": {
        "card": "c16",
        "option": 0,
        "slot": "fail"
      }
    },
    {
      "id": "m8",
      "kind": "claude",
      "status": "open",
      "text": "Enhancement powder should add 40% chance to success",
      "anchor": {
        "card": "c4",
        "option": 1,
        "slot": "fail"
      }
    },
    {
      "id": "m9",
      "kind": "claude",
      "status": "open",
      "text": "Requires Player consumes a Blast",
      "anchor": {
        "card": "c4",
        "option": 0,
        "slot": "result"
      }
    }
  ],
  "_layout": {
    "c:c1": [
      -491,
      9
    ],
    "b:church_approach": [
      522,
      -220
    ],
    "b:playground_approach": [
      492,
      866
    ],
    "b:hall_approach": [
      569,
      147
    ],
    "b:vein_not_seen": [
      2213,
      277
    ],
    "b:vein_seen": [
      2213,
      -157
    ],
    "b:harvested_seen": [
      2600,
      -258
    ],
    "b:claimed_vein_seen": [
      2598,
      -51
    ],
    "b:shrubbery": [
      1788,
      65
    ],
    "b:claimed_vein_not_seen": [
      2537,
      398
    ],
    "b:harvested_not_seen": [
      2536,
      156
    ],
    "c:c6": [
      1910,
      84
    ],
    "c:c4": [
      578,
      533
    ],
    "c:c3": [
      570,
      -214
    ],
    "c:c2": [
      672,
      320
    ],
    "c:c5": [
      1151,
      302
    ],
    "c:c7": [
      2216,
      261
    ],
    "c:c11": [
      2551,
      369
    ],
    "c:c12": [
      2555,
      163
    ],
    "c:c10": [
      2630,
      -16
    ],
    "c:c8": [
      2227,
      -150
    ],
    "c:c9": [
      2637,
      -267
    ],
    "end": [
      3607,
      162
    ],
    "b:fight_prep": [
      2957,
      -151
    ],
    "c:c14": [
      2815,
      369
    ],
    "b:church_caretaker": [
      1098,
      -343
    ],
    "b:church_vein_door": [
      1114,
      -109
    ],
    "c:c15": [
      1106,
      -86
    ],
    "c:c16": [
      1108,
      -336
    ],
    "b:church_caretaker_to_shrubbery": [
      1649,
      -290
    ],
    "b:hall_inside": [
      897,
      143
    ]
  }
}
```

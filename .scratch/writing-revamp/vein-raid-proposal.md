> RETIRED: this storyboard draft predates the stage-tree rebuild (.scratch/raid-events/raid-variants-proposal.md §3); data/events/vein_raid.json is now the source.

# vein_raid — imported from data/events/vein_raid.json

```json
{
  "id": "vein_raid",
  "repeatable": true,
  "observations": {
    "raid": {
      "mods": [],
      "blocks": {
        "physics": {
          "tiers": [
            {
              "base": 0.25,
              "text": "The back window's latch is rotten through. Someone has painted over it twice rather than replace it."
            },
            {
              "base": 0.55,
              "text": "There's a back window that might give with enough force. May not be quiet, though."
            }
          ],
          "miss": "Brick, shutters, a bolted gate. Nothing that moves."
        },
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "One guard is flagging, eyes half shut. His flask is empty and he keeps checking it anyway."
            },
            {
              "base": 0.55,
              "text": "One guard keeps shifting his weight, the way a man does at the end of a double shift."
            }
          ],
          "miss": "Four coats and a lot of breath. You can't tell who's awake."
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "The nearest guard is jumpy. He flinches at his own radio. Easy to rattle."
            },
            {
              "base": 0.55,
              "text": "One guard keeps glancing at the door, then at his phone, then at the door."
            }
          ],
          "miss": "Flat faces, arms folded. They've done this before."
        },
        "time": {
          "tiers": [
            {
              "base": 0.25,
              "text": "The patrol has a gap. You count it twice. Forty seconds, every round, like a bus timetable."
            },
            {
              "base": 0.55,
              "text": "The rounds run roughly on the quarter hour. Roughly."
            }
          ],
          "miss": "You can't make out any shift or predictable patrol routes."
        },
        "fate": {
          "tiers": [
            {
              "base": 0.25,
              "text": "You catch the moment one guard will turn away. A second before he does it."
            },
            {
              "base": 0.55,
              "text": "Something is about to go wrong for someone here. Not necessarily you."
            }
          ],
          "miss": "No chances you can see here. It's just a yard at night."
        }
      }
    }
  },
  "on_complete": [
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
          "key": "c1",
          "type": "tension",
          "label": "{today} — The approach",
          "speaker": null,
          "observe": "raid",
          "text": "Nobody has put a sign on this vein, but the ground still belongs to someone. You case the approach twice. No obvious watchers. That's not the same as no watchers."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "One way in. You commit or you don't.",
          "choices": [
            {
              "label": "Just go in",
              "check": {
                "base": 0.15,
                "raidFactors": true,
                "mods": []
              },
              "success": {
                "result_text": "You walk in like you belong. Tonight, nobody asks for a pass.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "You walk in. Someone asks for a pass.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Go in loud",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "raidCaught",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
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
              ],
              "result_text": "No point creeping. You hit the gate with your shoulder and go in hard.",
              "goto": {
                "branch": "b5"
              }
            },
            {
              "label": "Weigh the quiet ways in",
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
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "What you read, and what it buys you.",
          "choices": [
            {
              "label": "Take the window",
              "requires": {
                "observed": {
                  "id": "raid",
                  "ore": "physics",
                  "atLeast": 1
                }
              },
              "check": {
                "base": 0.6,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "physics",
                      "atLeast": 2
                    },
                    "add": 0.15,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "The latch gives, with a little flake of paint. You're in without a sound.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "The window sticks. Then it shrieks.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Wait out the tired guard",
              "requires": {
                "observed": {
                  "id": "raid",
                  "ore": "life",
                  "atLeast": 1
                }
              },
              "check": {
                "base": 0.6,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "life",
                      "atLeast": 2
                    },
                    "add": 0.15,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "He sits on a crate to rest his eyes. You step past before he finishes the thought.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  },
                  {
                    "op": "reduce_raid_guards",
                    "count": 1
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "He checks the flask once more and looks up.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Rattle a guard",
              "requires": {
                "observed": {
                  "id": "raid",
                  "ore": "emotion",
                  "atLeast": 1
                }
              },
              "check": {
                "base": 0.6,
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
                "result_text": "You mention his radio is picking something up. He goes to check.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  },
                  {
                    "op": "reduce_raid_guards",
                    "count": 1
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "He doesn't scare. He does look at you.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Look further",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b4"
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
          "key": "c4",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "More ways in, if you saw them.",
          "choices": [
            {
              "label": "Slip the patrol gap",
              "requires": {
                "observed": {
                  "id": "raid",
                  "ore": "time",
                  "atLeast": 1
                }
              },
              "check": {
                "base": 0.6,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "time",
                      "atLeast": 2
                    },
                    "add": 0.15,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "Forty seconds, as advertised. You use thirty-five.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "The round comes early. So much for the timetable.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Move as he turns",
              "requires": {
                "observed": {
                  "id": "raid",
                  "ore": "fate",
                  "atLeast": 1
                }
              },
              "check": {
                "base": 0.6,
                "mods": [
                  {
                    "observed": {
                      "id": "raid",
                      "ore": "fate",
                      "atLeast": 2
                    },
                    "add": 0.15,
                    "label": "A sharp read"
                  }
                ]
              },
              "success": {
                "result_text": "He turns to check his phone. You go.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "He doesn't turn. He's looking right at you.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Just go in",
              "check": {
                "base": 0.15,
                "raidFactors": true,
                "mods": []
              },
              "success": {
                "result_text": "You walk in like you belong. Tonight, nobody asks for a pass.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "You walk in. Someone asks for a pass.",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "raidCaught",
                    "value": true
                  },
                  {
                    "op": "notify",
                    "text": "Something moves that shouldn't. You've been seen."
                  },
                  {
                    "op": "start_raid_combat",
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
                ],
                "goto": {
                  "branch": "b5"
                }
              }
            },
            {
              "label": "Go in loud",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "raidCaught",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
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
              ],
              "result_text": "No point creeping. You hit the gate with your shoulder and go in hard.",
              "goto": {
                "branch": "b5"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b5"
      }
    },
    "b5": {
      "title": "From card 5",
      "cards": [
        {
          "key": "c5",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "The vein's yours to deal with, however you got here.",
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
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "repeatable",
      "observations",
      "cards",
      "on_complete"
    ],
    "cards": {
      "c1": [
        "key",
        "type",
        "label",
        "speaker",
        "observe",
        "text"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c5": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ]
    }
  },
  "_liveSource": "vein_raid.json",
  "_liveHash": "627e709a"
}
```

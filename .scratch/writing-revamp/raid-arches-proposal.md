# raid_arches — imported from data/events/raid_arches.json

```json
{
  "id": "raid_arches",
  "repeatable": true,
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
      ],
      "waves": 2
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
              "text": "PLACEHOLDER: physics t2: the shutter's manual release is reachable through the gap; vein position",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "neighbourArch"
                    }
                  },
                  "text": "PLACEHOLDER: physics t2 + neighbourArch: breeze-block wall shared with the next arch"
                }
              ]
            },
            {
              "base": 0.55,
              "text": "PLACEHOLDER: physics t1: the shutter's motor housing is cheap"
            }
          ],
          "miss": "PLACEHOLDER: physics miss: brick, steel, a shutter that is down"
        },
        "life": {
          "tiers": [
            {
              "base": 0.25,
              "text": "PLACEHOLDER: life t2: who is on the bench, who is in the back, the mechanic next door who knows everyone"
            },
            {
              "base": 0.55,
              "text": "PLACEHOLDER: life t1: someone is still on the bench"
            }
          ],
          "miss": "PLACEHOLDER: life miss: can't tell who is awake"
        },
        "emotion": {
          "tiers": [
            {
              "base": 0.25,
              "text": "PLACEHOLDER: emotion t2: the bench man will talk to anyone about the football; resents his bosses"
            },
            {
              "base": 0.55,
              "text": "PLACEHOLDER: emotion t1: the bench man is bored"
            }
          ],
          "miss": "PLACEHOLDER: emotion miss: flat faces"
        },
        "time": {
          "tiers": [
            {
              "base": 0.25,
              "text": "PLACEHOLDER: time t2: the timetable to the minute; the train covers noise",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cameras",
                      "atLeast": 1
                    }
                  },
                  "text": "PLACEHOLDER: time t2 + cameras: the camera sweep period"
                }
              ]
            },
            {
              "base": 0.55,
              "text": "PLACEHOLDER: time t1: trains run often"
            }
          ],
          "miss": "PLACEHOLDER: time miss: can't make out a timetable"
        },
        "fate": {
          "tiers": [
            {
              "base": 0.25,
              "text": "PLACEHOLDER: fate t2: exactly which train will not come",
              "variants": [
                {
                  "when": {
                    "security": {
                      "feature": "cameras",
                      "atLeast": 1
                    }
                  },
                  "text": "PLACEHOLDER: fate t2 + cameras: the camera on the shutter"
                }
              ]
            },
            {
              "base": 0.55,
              "text": "PLACEHOLDER: fate t1: a train is about to be late"
            }
          ],
          "miss": "PLACEHOLDER: fate miss: no chances you can see"
        }
      }
    }
  },
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "aReinfOpen",
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
          "key": "a_intro",
          "type": "tension",
          "label": "{today} — The approach",
          "speaker": null,
          "observe": "raid",
          "text": "PLACEHOLDER: the approach to the arch: no sign on the vein, ground still belongs to someone"
        },
        {
          "key": "a_front",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A roller shutter, a bench just inside, a trains-overhead arch. Three ways to start.",
          "choices": [
            {
              "label": "Knock: \"from next door\"",
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
                "result_text": "PLACEHOLDER: Knock: \"from next door\": success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Knock: \"from next door\": fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b18"
                }
              }
            },
            {
              "label": "Talk football with the bench man",
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
                "result_text": "PLACEHOLDER: Talk football with the bench man: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Talk football with the bench man: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b18"
                }
              }
            },
            {
              "label": "Release the shutter by hand",
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
                "base": 0.5,
                "entry": "physical",
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
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Release the shutter by hand: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b5"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Release the shutter by hand: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b18"
                }
              }
            },
            {
              "label": "Read the gaps…",
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
          "key": "a_front2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: What you saw buys other ways in.",
          "choices": [
            {
              "label": "Through the garage next door",
              "requires": {
                "all": [
                  {
                    "alert": {
                      "atMost": 1
                    }
                  },
                  {
                    "security": {
                      "feature": "neighbourArch"
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
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                }
              ],
              "result_text": "PLACEHOLDER: Through the garage next door",
              "goto": {
                "branch": "b9"
              }
            },
            {
              "label": "Round the back, over the railway fence",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "check": {
                "base": 0.45,
                "entry": "physical",
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
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Round the back, over the railway fence: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b11"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Round the back, over the railway fence: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b18"
                }
              }
            },
            {
              "label": "Louder, or stranger…",
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
          "key": "a_front3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Or don't be subtle.",
          "choices": [
            {
              "label": "Force the shutter",
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
                "result_text": "PLACEHOLDER: Force the shutter: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2,
                    "cover": {
                      "base": 0.35,
                      "mods": [
                        {
                          "observed": {
                            "id": "raid",
                            "ore": "time",
                            "atLeast": 2
                          },
                          "add": 0.35,
                          "label": "On the train"
                        }
                      ],
                      "text": "PLACEHOLDER: the train covers the noise"
                    }
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b28"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Force the shutter: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b28"
                }
              }
            },
            {
              "label": "Blast the shutter",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "mods": [
                      {
                        "observed": {
                          "id": "raid",
                          "ore": "time",
                          "atLeast": 2
                        },
                        "add": 0.35,
                        "label": "On the train"
                      }
                    ],
                    "text": "PLACEHOLDER: the train covers the noise"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Blast the shutter",
              "goto": {
                "branch": "b28"
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
                "result_text": "PLACEHOLDER: Wormhole: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Wormhole: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "atLeast": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b5"
      }
    },
    "b5": {
      "title": "From card 5",
      "cards": [
        {
          "key": "a_bench",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Past the bench, in the front of the arch.",
          "choices": [
            {
              "label": "Keep the story going",
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
                "result_text": "PLACEHOLDER: Keep the story going: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b7"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Keep the story going: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b17"
                }
              }
            },
            {
              "label": "Wait for him to turn to the radio",
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
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Wait for him to turn to the radio: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b7"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Wait for him to turn to the radio: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b17"
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
          "key": "a_bench2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Luck, or something you packed.",
          "choices": [
            {
              "label": "Hope the radio stays loud",
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
                "result_text": "PLACEHOLDER: Hope the radio stays loud: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b7"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hope the radio stays loud: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b17"
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                }
              ],
              "result_text": "PLACEHOLDER: Prophet's Breath: know when he turns",
              "goto": {
                "branch": "b7"
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
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                }
              ],
              "result_text": "PLACEHOLDER: Time Pearl: freeze and rush past",
              "goto": {
                "branch": "b7"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b7"
      }
    },
    "b7": {
      "title": "From card 7",
      "cards": [
        {
          "key": "a_partition",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The partition door to the back, and a lock.",
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
                "entry": "physical",
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
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Pick it quiet: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b34"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Pick it quiet: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
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
                "result_text": "PLACEHOLDER: Hope it isn't locked: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b34"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hope it isn't locked: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
                }
              }
            },
            {
              "label": "Rougher ways…",
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
          "key": "a_partition2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Doors open outward as well as inward.",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                }
              ],
              "result_text": "PLACEHOLDER: Walk in",
              "goto": {
                "branch": "b34"
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
                "result_text": "PLACEHOLDER: Force the door: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2,
                    "cover": {
                      "base": 0.35,
                      "mods": [
                        {
                          "observed": {
                            "id": "raid",
                            "ore": "time",
                            "atLeast": 2
                          },
                          "add": 0.35,
                          "label": "On the train"
                        }
                      ],
                      "text": "PLACEHOLDER: the train covers the noise"
                    }
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b34"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Force the door: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b34"
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "mods": [
                      {
                        "observed": {
                          "id": "raid",
                          "ore": "time",
                          "atLeast": 2
                        },
                        "add": 0.35,
                        "label": "On the train"
                      }
                    ],
                    "text": "PLACEHOLDER: the train covers the noise"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Blast the door",
              "goto": {
                "branch": "b34"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b9"
      }
    },
    "b9": {
      "title": "From card 9",
      "cards": [
        {
          "key": "a_garage",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The mechanic in the next arch.",
          "choices": [
            {
              "label": "Talk him into turning a blind eye",
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
                      "atLeast": 2
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
                "result_text": "PLACEHOLDER: Talk him into turning a blind eye: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b10"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Talk him into turning a blind eye: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Slip in while he's under a car",
              "requires": {
                "alert": {
                  "atMost": 1
                },
                "display": "hide"
              },
              "check": {
                "base": 0.36,
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
                "result_text": "PLACEHOLDER: Slip in while he's under a car: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b10"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Slip in while he's under a car: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Hope the radio stays up loud",
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
                "result_text": "PLACEHOLDER: Hope the radio stays up loud: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b10"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hope the radio stays up loud: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b10"
      }
    },
    "b10": {
      "title": "From card 10",
      "cards": [
        {
          "key": "a_wall",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The shared breeze-block wall.",
          "choices": [
            {
              "label": "Work the loose blocks quiet",
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
                "base": 0.4,
                "entry": "physical",
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
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Work the loose blocks quiet: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Work the loose blocks quiet: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
                }
              }
            },
            {
              "label": "Blast through the wall",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "mods": [
                      {
                        "observed": {
                          "id": "raid",
                          "ore": "time",
                          "atLeast": 2
                        },
                        "add": 0.35,
                        "label": "On the train"
                      }
                    ],
                    "text": "PLACEHOLDER: the train covers the noise"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Blast through the wall",
              "goto": {
                "branch": "b42"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b11"
      }
    },
    "b11": {
      "title": "From card 11",
      "cards": [
        {
          "key": "a_tracks",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Along the line, with the trains.",
          "choices": [
            {
              "label": "Cross between trains",
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
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Cross between trains: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b13"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Cross between trains: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b19"
                }
              }
            },
            {
              "label": "Hope there's no track crew tonight",
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
                "result_text": "PLACEHOLDER: Hope there's no track crew tonight: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b13"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hope there's no track crew tonight: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
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
          "key": "a_tracks2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Something packed, or the road home.",
          "choices": [
            {
              "label": "Prophet's Breath: know where the track worker is",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                }
              ],
              "result_text": "PLACEHOLDER: Prophet's Breath: know where the track worker is",
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
                "branch": "b16"
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
          "key": "a_vent",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The back vent, and its mesh.",
          "choices": [
            {
              "label": "Take the mesh off quiet",
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
                "entry": "physical",
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
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Take the mesh off quiet: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  }
                ],
                "goto": {
                  "branch": "b14"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Take the mesh off quiet: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b18"
                }
              }
            },
            {
              "label": "Kick it in on the train",
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
                "result_text": "PLACEHOLDER: Kick it in on the train: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2,
                    "cover": {
                      "base": 0.35,
                      "mods": [
                        {
                          "observed": {
                            "id": "raid",
                            "ore": "time",
                            "atLeast": 2
                          },
                          "add": 0.35,
                          "label": "On the train"
                        }
                      ],
                      "text": "PLACEHOLDER: the train covers the noise"
                    }
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b14"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Kick it in on the train: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": true
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": false
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b14"
                }
              }
            },
            {
              "label": "Blast the vent",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": true
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": false
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "mods": [
                      {
                        "observed": {
                          "id": "raid",
                          "ore": "time",
                          "atLeast": 2
                        },
                        "add": 0.35,
                        "label": "On the train"
                      }
                    ],
                    "text": "PLACEHOLDER: the train covers the noise"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Blast the vent",
              "goto": {
                "branch": "b14"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b14"
      }
    },
    "b14": {
      "title": "From card 14",
      "cards": [
        {
          "key": "a_crawl",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A drop into the back of the arch, and a guard in it.",
          "choices": [
            {
              "label": "Wait for him to turn his back",
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
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Wait for him to turn his back: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Wait for him to turn his back: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
                }
              }
            },
            {
              "label": "Hope he turns",
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
                "result_text": "PLACEHOLDER: Hope he turns: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hope he turns: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b20"
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Prophet's Breath: know when he turns",
              "goto": {
                "branch": "b42"
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b15"
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
          "key": "a_crawl2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Freeze the back, or give up on it.",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Time Pearl: freeze him",
              "goto": {
                "branch": "b42"
              }
            },
            {
              "label": "Back out…",
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
          "key": "a_retreat",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: You could still walk away.",
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
              "result_text": "PLACEHOLDER: backed out",
              "goto": {
                "branch": "b48"
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
                "result_text": "PLACEHOLDER: Run for it: success",
                "effects": [
                  {
                    "op": "back_out"
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Run for it: fail",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b32"
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
                "result_text": "PLACEHOLDER: Wormhole out: success",
                "effects": [
                  {
                    "op": "back_out"
                  }
                ],
                "goto": {
                  "branch": "b48"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Wormhole out: fail",
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
                  "branch": "b32"
                }
              }
            },
            {
              "label": "Carry on",
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
        "branch": "b17"
      }
    },
    "b17": {
      "title": "From card 17",
      "cards": [
        {
          "key": "a_seen_bench",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: the bench man has seen you"
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b28"
        },
        {
          "branch": "b23"
        }
      ]
    },
    "b18": {
      "title": "From card 18",
      "cards": [
        {
          "key": "a_seen_out",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: someone outside has seen you"
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b26"
        },
        {
          "branch": "b21"
        }
      ]
    },
    "b19": {
      "title": "From card 19",
      "cards": [
        {
          "key": "a_seen_wit",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: a witness has seen you"
        }
      ],
      "then": [
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b26"
        },
        {
          "branch": "b25"
        }
      ]
    },
    "b20": {
      "title": "From card 20",
      "cards": [
        {
          "key": "a_seen_in",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: someone inside has seen you"
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
          "branch": "b28"
        },
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b26"
        },
        {
          "branch": "b23"
        }
      ]
    },
    "b21": {
      "title": "From card 21",
      "cards": [
        {
          "key": "a_win_out",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Someone outside has seen you.",
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
              "result_text": "PLACEHOLDER: Take him down",
              "goto": {
                "branch": "b32"
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
                "result_text": "PLACEHOLDER: Talk it out: success",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Talk it out: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b26"
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
                "result_text": "PLACEHOLDER: Duck out of sight: success",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Duck out of sight: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b26"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b22"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b22"
      }
    },
    "b22": {
      "title": "From card 22",
      "cards": [
        {
          "key": "a_win_out2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Something packed, or the road home.",
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
              "result_text": "PLACEHOLDER: Pan's Rapture",
              "goto": {
                "branch": "b32"
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
                  "flag": "aReinfOpen",
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
              "result_text": "PLACEHOLDER: Blast him",
              "goto": {
                "branch": "b32"
              }
            },
            {
              "label": "Run for it",
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
        "branch": "b23"
      }
    },
    "b23": {
      "title": "From card 23",
      "cards": [
        {
          "key": "a_win_in",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Someone inside has seen you.",
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
              "result_text": "PLACEHOLDER: Take him down",
              "goto": {
                "branch": "b32"
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
                "result_text": "PLACEHOLDER: Talk it out: success",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Talk it out: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b28"
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
                "result_text": "PLACEHOLDER: Duck out of sight: success",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Duck out of sight: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b28"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b24"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b24"
      }
    },
    "b24": {
      "title": "From card 24",
      "cards": [
        {
          "key": "a_win_in2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Something packed, or the road home.",
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
              "result_text": "PLACEHOLDER: Pan's Rapture",
              "goto": {
                "branch": "b32"
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
                  "flag": "aReinfOpen",
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
              "result_text": "PLACEHOLDER: Blast him",
              "goto": {
                "branch": "b32"
              }
            },
            {
              "label": "Run for it",
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
        "branch": "b25"
      }
    },
    "b25": {
      "title": "From card 25",
      "cards": [
        {
          "key": "a_win_wit",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A witness has seen you. Not a guard.",
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
                "result_text": "PLACEHOLDER: Talk it out: success",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Talk it out: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b26"
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
                "result_text": "PLACEHOLDER: Duck out of sight: success",
                "effects": [
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Duck out of sight: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b26"
                }
              }
            },
            {
              "label": "Run for it",
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
        "branch": "b26"
      }
    },
    "b26": {
      "title": "From card 26",
      "cards": [
        {
          "key": "a_alarm",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The arch is awake and looking.",
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
                "result_text": "PLACEHOLDER: Hide: success",
                "effects": [],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hide: fail",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b32"
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
                "result_text": "PLACEHOLDER: Bluff: success",
                "effects": [],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Bluff: fail",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b32"
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
              "result_text": "PLACEHOLDER: Pan's Rapture",
              "goto": {
                "branch": "b32"
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
          "key": "a_alarm2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Scare them off, or leave.",
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
                    "base": 0.5,
                    "text": "PLACEHOLDER: they scatter without a sound"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Panic",
              "goto": {
                "branch": "b32"
              }
            },
            {
              "label": "Run for it",
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
        "branch": "b28"
      }
    },
    "b28": {
      "title": "From card 28",
      "cards": [
        {
          "key": "post",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The bench, and the guards between you and the way on.",
          "choices": [
            {
              "label": "Fight",
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards"
                }
              ],
              "result_text": "PLACEHOLDER: Fight",
              "goto": {
                "branch": "b32"
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
                "result_text": "PLACEHOLDER: Bluff past: success",
                "effects": [],
                "goto": {
                  "branch": "b32"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Bluff past: fail",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  },
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b32"
                }
              }
            },
            {
              "label": "Other ways…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b29"
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
          "key": "post2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Something packed.",
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
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Prophet's Breath: skip the post",
              "goto": {
                "branch": "b32"
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
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Time Pearl: freeze and rush past",
              "goto": {
                "branch": "b32"
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
              "result_text": "PLACEHOLDER: Time Pearl: freeze the line guard",
              "goto": {
                "branch": "b32"
              }
            },
            {
              "label": "More…",
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
          "key": "post3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Something that makes a post lose its head.",
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
                  "flag": "aReinfOpen",
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
                      "enemyStartsHurt": 0.25
                    }
                  ]
                }
              ],
              "result_text": "PLACEHOLDER: Pandemonium",
              "goto": {
                "branch": "b32"
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
                    "base": 0.5,
                    "text": "PLACEHOLDER: they scatter without a sound"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Panic",
              "goto": {
                "branch": "b32"
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
              "result_text": "PLACEHOLDER: Pan's Rapture",
              "goto": {
                "branch": "b32"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b31"
      }
    },
    "b31": {
      "title": "From card 31",
      "cards": [
        {
          "key": "a_reinf",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: More of them arrive.",
          "choices": [
            {
              "label": "Keep moving",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": false
                }
              ],
              "result_text": null,
              "goto": {
                "branch": "b33"
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
          "key": "a_resume",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: You carry on."
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
                "flag": "aReinfOpen"
              }
            ]
          },
          "branch": "b31"
        },
        {
          "branch": "b33"
        }
      ]
    },
    "b33": {
      "title": "From card 33",
      "cards": [
        {
          "key": "a_resume2",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: You carry on."
        }
      ],
      "then": [
        {
          "if": {
            "flag": "aAt_bench"
          },
          "branch": "b5"
        },
        {
          "if": {
            "flag": "aAt_partition"
          },
          "branch": "b7"
        },
        {
          "if": {
            "flag": "aAt_garage"
          },
          "branch": "b9"
        },
        {
          "if": {
            "flag": "aAt_wall"
          },
          "branch": "b10"
        },
        {
          "if": {
            "flag": "aAt_tracks"
          },
          "branch": "b11"
        },
        {
          "if": {
            "flag": "aAt_vent"
          },
          "branch": "b13"
        },
        {
          "if": {
            "flag": "aAt_crawl"
          },
          "branch": "b14"
        },
        {
          "if": {
            "flag": "aAt_inside"
          },
          "branch": "b34"
        },
        {
          "branch": "b42"
        }
      ]
    },
    "b34": {
      "title": "From card 34",
      "cards": [
        {
          "key": "a_inside",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The back of the arch."
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
          "branch": "b38"
        }
      ]
    },
    "b35": {
      "title": "From card 35",
      "cards": [
        {
          "key": "a_cam",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A camera on the shutter, facing in.",
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
                    "alertByTier": [
                      0,
                      -0.1,
                      -0.25
                    ]
                  }
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Time the sweep: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b38"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Time the sweep: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
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
                "base": 0.5,
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
                "result_text": "PLACEHOLDER: Stay in its blind spot: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b38"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Stay in its blind spot: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
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
                "result_text": "PLACEHOLDER: Hope it's on the blink: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b38"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Hope it's on the blink: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": 1
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
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
              "effects": [],
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
          "key": "a_cam2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A camera is a system. It can't be talked round.",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Time Pearl: freeze it",
              "goto": {
                "branch": "b38"
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                },
                {
                  "op": "alert",
                  "atLeast": 2,
                  "cover": {
                    "base": 0.35,
                    "text": "PLACEHOLDER: the train covers the noise"
                  }
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: Blast it",
              "goto": {
                "branch": "b38"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b37"
      }
    },
    "b37": {
      "title": "From card 37",
      "cards": [
        {
          "key": "a_win_cam",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: They'll be coming to look at the screen.",
          "choices": [
            {
              "label": "Take him down",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                },
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards",
                  "waves": 1
                }
              ],
              "result_text": "PLACEHOLDER: Take him down",
              "goto": {
                "branch": "b38"
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
                "result_text": "PLACEHOLDER: Duck out of sight: success",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "add": -1
                  }
                ],
                "goto": {
                  "branch": "b38"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: Duck out of sight: fail",
                "effects": [
                  {
                    "op": "set_flag",
                    "flag": "aAt_bench",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_partition",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_garage",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_wall",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_tracks",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_vent",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_crawl",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_inside",
                    "value": false
                  },
                  {
                    "op": "set_flag",
                    "flag": "aAt_room",
                    "value": true
                  },
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  }
                ],
                "goto": {
                  "branch": "b38"
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                },
                {
                  "op": "alert",
                  "atLeast": 2
                },
                {
                  "op": "set_flag",
                  "flag": "aReinfOpen",
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
              "result_text": "PLACEHOLDER: Blast him",
              "goto": {
                "branch": "b38"
              }
            },
            {
              "label": "Back out…",
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
        "branch": "b38"
      }
    },
    "b38": {
      "title": "From card 38",
      "cards": [
        {
          "key": "a_threshold",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The partition at the back of the arch."
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
          "branch": "b39"
        },
        {
          "branch": "b42"
        }
      ]
    },
    "b39": {
      "title": "From card 39",
      "cards": [
        {
          "key": "a_ward",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A ward on the threshold, faint as a draught.",
          "choices": [
            {
              "label": "Step through",
              "effects": [
                {
                  "op": "ward_trigger"
                }
              ],
              "result_text": "PLACEHOLDER: You step through. The air rings once.",
              "goto": {
                "branch": "b42"
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
                "result_text": "PLACEHOLDER: Through the gap in it.",
                "effects": [],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: It notices.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b42"
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
                "result_text": "PLACEHOLDER: It spends itself on the decoy. You wait, then go.",
                "effects": [],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: It ignores the decoy and takes you.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              }
            },
            {
              "label": "Other ways…",
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
          "key": "a_ward2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Something packed, or someone else.",
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
                "result_text": "PLACEHOLDER: He steps through it. You step round him.",
                "effects": [
                  {
                    "op": "reduce_raid_guards",
                    "count": 1
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: He doesn't fall for it. The ward falls for you.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b42"
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
              "result_text": "PLACEHOLDER: Faster than it can notice.",
              "goto": {
                "branch": "b42"
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
                "result_text": "PLACEHOLDER: The ward is on the other side of you.",
                "effects": [],
                "goto": {
                  "branch": "b42"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: The fold lands short.",
                "effects": [
                  {
                    "op": "ward_trigger"
                  }
                ],
                "goto": {
                  "branch": "b42"
                }
              }
            },
            {
              "label": "More…",
              "reselectable": true,
              "effects": [],
              "result_text": null,
              "goto": {
                "branch": "b41"
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
          "key": "a_ward3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: A ward is a system. Stop it.",
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: The ward stops. You don't.",
              "goto": {
                "branch": "b42"
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
                "branch": "b16"
              }
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
          "key": "a_room",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: The vein room: low light, a hum in the floor, and guards standing on the vein.",
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
              "result_text": "PLACEHOLDER: They don't give it up.",
              "goto": {
                "branch": "b43"
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
              "result_text": "PLACEHOLDER: Nobody stops you.",
              "goto": {
                "branch": "b43"
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
                "result_text": "PLACEHOLDER: They let you by.",
                "effects": [],
                "goto": {
                  "branch": "b43"
                }
              },
              "fail": {
                "result_text": "PLACEHOLDER: They don't.",
                "effects": [
                  {
                    "op": "alert",
                    "atLeast": 2
                  },
                  {
                    "op": "set_flag",
                    "flag": "aReinfOpen",
                    "value": true
                  },
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ],
                "goto": {
                  "branch": "b43"
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
                  "flag": "aAt_bench",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_partition",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_garage",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_wall",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_tracks",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_vent",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_crawl",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_inside",
                  "value": false
                },
                {
                  "op": "set_flag",
                  "flag": "aAt_room",
                  "value": true
                }
              ],
              "result_text": "PLACEHOLDER: You know where each of them will be.",
              "goto": {
                "branch": "b43"
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
        "branch": "b43"
      }
    },
    "b43": {
      "title": "From card 43",
      "cards": [
        {
          "key": "a_claim_route",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "The vein runs under the floor here, warm through your shoes."
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
          "branch": "b44"
        },
        {
          "if": {
            "alert": {
              "atLeast": 2
            }
          },
          "branch": "b46"
        },
        {
          "branch": "b45"
        }
      ]
    },
    "b44": {
      "title": "From card 44",
      "cards": [
        {
          "key": "a_final",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: Boots in the corridor. They're nearly here.",
          "choices": [
            {
              "label": "Reach for the vein",
              "effects": [
                {
                  "op": "start_raid_combat",
                  "preset": "veinGuards"
                }
              ],
              "result_text": "PLACEHOLDER: You reach for the vein with the footsteps getting louder.",
              "goto": {
                "branch": "b46"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b45"
      }
    },
    "b45": {
      "title": "From card 45",
      "cards": [
        {
          "key": "a_claim",
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
      ],
      "then": "end"
    },
    "b46": {
      "title": "From card 46",
      "cards": [
        {
          "key": "a_claim_a",
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
              "result_text": "You take it outright. Word gets round fast — it always does — and the relationship with whoever ran this patch takes the hit that comes with being seen to do it.",
              "goto": {
                "branch": "b47"
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
                "branch": "b47"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b47"
      }
    },
    "b47": {
      "title": "From card 47",
      "cards": [
        {
          "key": "a_getaway",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: the way out is not the way you came",
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
                "result_text": "PLACEHOLDER: You run. Nobody catches you.",
                "effects": []
              },
              "fail": {
                "result_text": "PLACEHOLDER: They catch you at the gate.",
                "effects": [
                  {
                    "op": "start_raid_combat",
                    "preset": "veinGuards"
                  }
                ]
              }
            },
            {
              "label": "Along the tracks",
              "check": {
                "base": 0.6,
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
                  }
                ]
              },
              "success": {
                "result_text": "PLACEHOLDER: Along the tracks: success",
                "effects": []
              },
              "fail": {
                "result_text": "PLACEHOLDER: Along the tracks: fail",
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
                "result_text": "PLACEHOLDER: The fold takes you out.",
                "effects": []
              },
              "fail": {
                "result_text": "PLACEHOLDER: The fold lands short.",
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
    "b48": {
      "title": "From card 48",
      "cards": [
        {
          "key": "a_out",
          "type": "tension",
          "label": null,
          "speaker": null,
          "text": "PLACEHOLDER: you walk away, and nobody ever knows you were here"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "repeatable",
      "fightPresets",
      "observations",
      "cards",
      "on_complete"
    ],
    "cards": {
      "a_intro": [
        "key",
        "type",
        "label",
        "speaker",
        "observe",
        "text"
      ],
      "a_front": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_front2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_front3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_bench": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_bench2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_partition": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_partition2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_garage": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_wall": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_tracks": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_tracks2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_vent": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_crawl": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_crawl2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_retreat": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_seen_bench": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_seen_out": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_seen_wit": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_seen_in": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_win_out": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_win_out2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_win_in": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_win_in2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_win_wit": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_alarm": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_alarm2": [
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
      "a_reinf": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_resume": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_resume2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_inside": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_cam": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_cam2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_win_cam": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_threshold": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_ward": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_ward2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_ward3": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_room": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_claim_route": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "a_final": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_claim": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "end",
        "choices"
      ],
      "a_claim_a": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "a_getaway": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "end",
        "choices"
      ],
      "a_out": [
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
  "_liveSource": "raid_arches.json",
  "_liveHash": "05dc8018"
}
```

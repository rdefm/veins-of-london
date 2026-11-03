# board_meeting — imported from data/events/board_meeting.json

```json
{
  "id": "board_meeting",
  "fillFromContext": true,
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "phone"
    },
    {
      "op": "open_morning_accounts"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "minutes",
          "type": "narration",
          "label": "Bermondsey - James's workshop",
          "speaker": null,
          "text": "Monday. Archie has the minutes on his phone. {minutes}"
        },
        {
          "key": "opener",
          "type": "speaker",
          "label": null,
          "speaker": "{opener_speaker}",
          "text": "{opener}"
        }
      ],
      "then": [
        {
          "if": {
            "context_flag": "none"
          },
          "branch": "b14"
        },
        {
          "branch": "b3"
        }
      ]
    },
    "b3": {
      "title": "From card 3",
      "cards": [
        {
          "key": "case_0",
          "type": "speaker",
          "label": null,
          "speaker": "{c0_pitcher}",
          "text": "{c0_case}"
        },
        {
          "key": "resp_0",
          "type": "speaker",
          "label": null,
          "speaker": "{c0_resp_speaker}",
          "text": "{c0_resp}"
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "context_flag": "c0_norebut"
              },
              {
                "context_flag": "c0_last"
              },
              {
                "context_flag": "noclash"
              }
            ]
          },
          "branch": "b14"
        },
        {
          "if": {
            "all": [
              {
                "context_flag": "c0_norebut"
              },
              {
                "context_flag": "c0_last"
              }
            ]
          },
          "branch": "b12"
        },
        {
          "if": {
            "context_flag": "c0_norebut"
          },
          "branch": "b6"
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
          "key": "reb_0",
          "type": "speaker",
          "label": null,
          "speaker": "{c0_pitcher}",
          "text": "{c0_reb}"
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "context_flag": "c0_last"
              },
              {
                "context_flag": "noclash"
              }
            ]
          },
          "branch": "b14"
        },
        {
          "if": {
            "context_flag": "c0_last"
          },
          "branch": "b12"
        },
        {
          "branch": "b6"
        }
      ]
    },
    "b6": {
      "title": "From card 6",
      "cards": [
        {
          "key": "case_1",
          "type": "speaker",
          "label": null,
          "speaker": "{c1_pitcher}",
          "text": "{c1_case}"
        },
        {
          "key": "resp_1",
          "type": "speaker",
          "label": null,
          "speaker": "{c1_resp_speaker}",
          "text": "{c1_resp}"
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "context_flag": "c1_norebut"
              },
              {
                "context_flag": "c1_last"
              },
              {
                "context_flag": "noclash"
              }
            ]
          },
          "branch": "b14"
        },
        {
          "if": {
            "all": [
              {
                "context_flag": "c1_norebut"
              },
              {
                "context_flag": "c1_last"
              }
            ]
          },
          "branch": "b12"
        },
        {
          "if": {
            "context_flag": "c1_norebut"
          },
          "branch": "b9"
        },
        {
          "branch": "b8"
        }
      ]
    },
    "b8": {
      "title": "From card 8",
      "cards": [
        {
          "key": "reb_1",
          "type": "speaker",
          "label": null,
          "speaker": "{c1_pitcher}",
          "text": "{c1_reb}"
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "context_flag": "c1_last"
              },
              {
                "context_flag": "noclash"
              }
            ]
          },
          "branch": "b14"
        },
        {
          "if": {
            "context_flag": "c1_last"
          },
          "branch": "b12"
        },
        {
          "branch": "b9"
        }
      ]
    },
    "b9": {
      "title": "From card 9",
      "cards": [
        {
          "key": "case_2",
          "type": "speaker",
          "label": null,
          "speaker": "{c2_pitcher}",
          "text": "{c2_case}"
        },
        {
          "key": "resp_2",
          "type": "speaker",
          "label": null,
          "speaker": "{c2_resp_speaker}",
          "text": "{c2_resp}"
        }
      ],
      "then": [
        {
          "if": {
            "all": [
              {
                "context_flag": "c2_norebut"
              },
              {
                "context_flag": "noclash"
              }
            ]
          },
          "branch": "b14"
        },
        {
          "if": {
            "context_flag": "c2_norebut"
          },
          "branch": "b12"
        },
        {
          "branch": "b11"
        }
      ]
    },
    "b11": {
      "title": "From card 11",
      "cards": [
        {
          "key": "reb_2",
          "type": "speaker",
          "label": null,
          "speaker": "{c2_pitcher}",
          "text": "{c2_reb}"
        }
      ],
      "then": [
        {
          "if": {
            "context_flag": "noclash"
          },
          "branch": "b14"
        },
        {
          "branch": "b12"
        }
      ]
    },
    "b12": {
      "title": "From card 12",
      "cards": [
        {
          "key": "clash_a",
          "type": "speaker",
          "label": null,
          "speaker": "{clash_a_speaker}",
          "text": "{clash_a}"
        },
        {
          "key": "clash_b",
          "type": "speaker",
          "label": null,
          "speaker": "{clash_b_speaker}",
          "text": "{clash_b}",
          "goto": {
            "branch": "b14"
          }
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
          "key": "vote",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "{voteText}",
          "choicesFromContext": "agenda",
          "choices": [
            {
              "id": "skip",
              "label": "Leave it to Archie",
              "exit": true,
              "effects": [
                {
                  "op": "board_skip"
                }
              ],
              "result_text": "\"You weren't there, so you're doing mine.\"",
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
          "key": "aob",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "{aob}"
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "fillFromContext",
      "cards",
      "on_complete"
    ],
    "cards": {
      "minutes": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "opener": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "case_0": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "resp_0": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "reb_0": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "case_1": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "resp_1": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "reb_1": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "case_2": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "resp_2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "reb_2": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "clash_a": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "clash_b": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "goto"
      ],
      "vote": [
        "key",
        "type",
        "label",
        "speaker",
        "text",
        "choicesFromContext",
        "choices"
      ],
      "aob": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_keyLinks": true,
  "_liveSource": "board_meeting.json",
  "_liveHash": "b7b62026"
}
```

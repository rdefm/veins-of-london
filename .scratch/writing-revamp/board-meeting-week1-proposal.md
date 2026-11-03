# board_meeting_week1 — imported from data/events/board_meeting_week1.json

```json
{
  "id": "board_meeting_week1",
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
          "key": "intro",
          "type": "narration",
          "label": "Bermondsey - James's workshop",
          "speaker": null,
          "text": "Archie has pushed two benches together and set a Tesco meal deal at each place. Owen has been given a chair again."
        },
        {
          "key": "explain",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Board meeting. Every Monday, catering provided.\" He taps his sandwich. \"Each of us pitches a goal and we argue it out in front of you. Then you pick which one we chase this week.\""
        },
        {
          "key": "rules",
          "type": "speaker",
          "label": null,
          "speaker": "James",
          "text": "\"Next Monday I read the minutes and we find out whether you chose well. We'll argue. You decide. Nobody is wounded if it isn't theirs.\""
        },
        {
          "key": "next_week",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"Worst you'll get is 'next week, then'. Then I pitch again, louder.\""
        },
        {
          "key": "owen",
          "type": "speaker",
          "label": null,
          "speaker": "Owen",
          "text": "\"Sorry. Do I have a vote?\""
        },
        {
          "key": "poach",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"You're getting poached, Owen. Different department. Start Friday.\" James does not look up. \"He is not.\""
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
          "branch": "b19"
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
          "branch": "b19"
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
          "branch": "b17"
        },
        {
          "if": {
            "context_flag": "c0_norebut"
          },
          "branch": "b11"
        },
        {
          "branch": "b10"
        }
      ]
    },
    "b10": {
      "title": "From card 10",
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
          "branch": "b19"
        },
        {
          "if": {
            "context_flag": "c0_last"
          },
          "branch": "b17"
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
          "branch": "b19"
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
          "branch": "b17"
        },
        {
          "if": {
            "context_flag": "c1_norebut"
          },
          "branch": "b14"
        },
        {
          "branch": "b13"
        }
      ]
    },
    "b13": {
      "title": "From card 13",
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
          "branch": "b19"
        },
        {
          "if": {
            "context_flag": "c1_last"
          },
          "branch": "b17"
        },
        {
          "branch": "b14"
        }
      ]
    },
    "b14": {
      "title": "From card 14",
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
          "branch": "b19"
        },
        {
          "if": {
            "context_flag": "c2_norebut"
          },
          "branch": "b17"
        },
        {
          "branch": "b16"
        }
      ]
    },
    "b16": {
      "title": "From card 16",
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
          "branch": "b19"
        },
        {
          "branch": "b17"
        }
      ]
    },
    "b17": {
      "title": "From card 17",
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
            "branch": "b19"
          }
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
                "branch": "b20"
              }
            }
          ]
        }
      ],
      "then": {
        "branch": "b20"
      }
    },
    "b20": {
      "title": "From card 20",
      "cards": [
        {
          "key": "aob",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Any other business. James asks that the benches be put back exactly where they were. Owen asks which of them is Friday."
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
      "intro": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "explain": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "rules": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "next_week": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "owen": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "poach": [
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
  "_liveSource": "board_meeting_week1.json",
  "_liveHash": "632f9a5a"
}
```

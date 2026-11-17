# col_a2_hakim_retake — imported from data/events/col_a2_hakim_retake.json

```json
{
  "id": "col_a2_hakim_retake",
  "on_complete": [
    {
      "op": "faction_relation",
      "faction": "collective",
      "value": 15
    },
    {
      "op": "set_flag",
      "flag": "colA2HakimRetaken",
      "value": true
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
          "key": "c1",
          "type": "narration",
          "label": "Whitechapel Road",
          "speaker": null,
          "text": "The padlock on the yard gate is still the Firm's. Hakim watches it from the shop doorway, the way you'd watch the weather."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"Nadia says you've been asking about it.\" He wipes his hands on his apron, though they're clean. \"I don't want anyone getting hurt over a yard. Sorry. I know that's not much help.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Two ways through that gate.",
          "choices": [
            {
              "label": "Take it back",
              "effects": [
                {
                  "op": "claim_faction_vein",
                  "veinIdStatePath": "collective.hakimVeinId"
                },
                {
                  "op": "col_a2_ruin_site"
                }
              ],
              "result_text": "You go in at the hour the handler said. The chain's cheap, and the man meant to be watching it is round the corner on his phone. It takes less time than the kettle."
            },
            {
              "label": "Buy it back",
              "effects": [
                {
                  "op": "buy_faction_vein",
                  "veinIdStatePath": "collective.hakimVeinId",
                  "faction": "firm"
                },
                {
                  "op": "col_a2_ruin_site"
                }
              ],
              "result_text": "The Firm's man meets you at the gate with the paperwork already filled in. \"Same price as anyone's. It was only ever a yard to us.\" He hands over the key to his padlock and doesn't look back at it."
            }
          ]
        },
        {
          "key": "c4",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Hakim opens the gate himself. It takes him two goes with the key."
        },
        {
          "key": "c5",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "The yard is as it was. The bins, the broken pallet, the drain in the corner. He crouches and puts his palm flat on the concrete, the way his uncle used to, and keeps it there a while."
        },
        {
          "key": "c6",
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"Well.\" He stands, and his knees crack. \"It's ours. Thank you. Really.\""
        },
        {
          "key": "c7",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He locks the gate behind you both, with his own padlock this time."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "cards",
      "on_complete"
    ],
    "cards": {
      "c1": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
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
        "text"
      ],
      "c5": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c6": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c7": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4",
      "c5",
      "c6",
      "c7"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a2_hakim_retake.json",
  "_liveHash": "73bdfdbe"
}
```

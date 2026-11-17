# col_a2_contested_vein — imported from data/events/col_a2_contested_vein.json

```json
{
  "id": "col_a2_contested_vein",
  "pin": {
    "district": "camden",
    "showWhenFlagsTrue": [
      "colA2Stage"
    ],
    "showWhenFlagsFalse": [
      "colA2ContestedVeinDone"
    ]
  },
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA2ContestedVeinDone",
      "value": true
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
          "key": "c1",
          "type": "narration",
          "label": "Camden",
          "speaker": null,
          "text": "A lock-up off the market that used to be Collective ground. Somebody's changed the padlock. Nobody saw it happen, or nobody's saying."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"That one's the Firm's now. Since sometime after Hakim. Nobody rang to tell us - we just noticed the takings stopped.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "Two ways to have it back.",
          "choices": [
            {
              "label": "Take it back",
              "effects": [
                {
                  "op": "claim_faction_vein",
                  "siteIdStatePath": "collective.contestedVeinSiteId"
                },
                {
                  "op": "log_method",
                  "key": "a2ContestedVein",
                  "value": "force"
                }
              ],
              "result_text": "You go in like it's still yours, because it still should be. Nobody's there to argue. That doesn't mean nobody notices."
            },
            {
              "label": "Buy it back",
              "effects": [
                {
                  "op": "buy_faction_vein",
                  "siteIdStatePath": "collective.contestedVeinSiteId",
                  "faction": "firm"
                },
                {
                  "op": "log_method",
                  "key": "a2ContestedVein",
                  "value": "bought"
                }
              ],
              "result_text": "\"You want it back, there's a price, same as anyone's. We're not precious about it. It's only business, at the end of the day.\" He counts it without looking up. It is the least interesting thing that has happened to him all week."
            }
          ]
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Either way, the lock-up is yours again. Whether it feels like it is a separate question, for later."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "pin",
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
      ]
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a2_contested_vein.json",
  "_liveHash": "74c7beea"
}
```

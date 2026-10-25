# col_a1_firm_intimidation — imported from data/events/col_a1_firm_intimidation.json

```json
{
  "id": "col_a1_firm_intimidation",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA1IntimidationSeen",
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
          "label": null,
          "speaker": null,
          "text": "Three of them, waiting by your exit, in no particular hurry. The one in front has the patient look of somebody doing an errand."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Firm Man",
          "text": "\"You've been busy. Fate, physics — bit ambitious for someone who was doing a rent-a-vein in Whitechapel a month ago.\""
        },
        {
          "key": "c3",
          "type": "speaker",
          "label": null,
          "speaker": "Firm Man",
          "text": "\"Nobody's asking you to stop. Just letting you know it's been noticed. There's a difference, and the difference is entirely up to you.\""
        },
        {
          "key": "c4",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "He hasn't threatened you. He's been very careful not to.",
          "choices": [
            {
              "label": "Back off",
              "effects": [
                {
                  "op": "log_method",
                  "key": "firmFirstContact",
                  "value": "backed_off"
                }
              ],
              "result_text": "You take the long way round. Nothing happens, which is the point — somebody wanted a face and now has one."
            },
            {
              "label": "Hold your ground",
              "effects": [
                {
                  "op": "log_method",
                  "key": "firmFirstContact",
                  "value": "held"
                }
              ],
              "result_text": "You don't move and you don't say anything. He waits, decides it isn't worth the afternoon, and they go. He is slightly less pleasant on the way past."
            },
            {
              "label": "Tell them where to go",
              "effects": [
                {
                  "op": "log_method",
                  "key": "firmFirstContact",
                  "value": "fought"
                },
                {
                  "op": "start_street_mugging"
                }
              ],
              "result_text": "You tell him. There is a moment where it could still go either way, and then it doesn't."
            }
          ]
        },
        {
          "key": "c5",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "The patches are still yours to give away. That was never what this was about."
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
        "text"
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
        "text"
      ]
    }
  },
  "_liveSource": "col_a1_firm_intimidation.json",
  "_liveHash": "80091215"
}
```

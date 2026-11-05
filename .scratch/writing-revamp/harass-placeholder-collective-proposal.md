# harass_placeholder_collective — imported from data/events/harass_placeholder_collective.json

```json
{
  "id": "harass_placeholder_collective",
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
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: a noise complaint, lodged by a neighbour you have never met."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: the council would like quiet.",
          "choices": [
            {
              "label": "Keep it quiet",
              "effects": [
                {
                  "op": "harassment_add",
                  "kind": "workBan",
                  "params": {
                    "block": "morning",
                    "days": 7
                  }
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: no work at the vein in the mornings for a week."
            },
            {
              "label": "Pay it off (£100)",
              "effects": [
                {
                  "op": "fine",
                  "amount": 100
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: the complaint is withdrawn."
            }
          ]
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
        "text",
        "choices"
      ]
    }
  },
  "_liveSource": "harass_placeholder_collective.json",
  "_liveHash": "cce1b230"
}
```

# harass_placeholder_conclave — imported from data/events/harass_placeholder_conclave.json

```json
{
  "id": "harass_placeholder_conclave",
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
          "text": "PROSE-REVIEW placeholder: an injunction, served by hand, concerning one of your veins."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: a hearing has been scheduled.",
          "choices": [
            {
              "label": "Attend the hearing",
              "effects": [
                {
                  "op": "spend_block",
                  "count": 1
                },
                {
                  "op": "fine",
                  "amount": 100
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: a morning of paperwork and a fine. The injunction is lifted."
            },
            {
              "label": "Ignore it",
              "effects": [
                {
                  "op": "harassment_add",
                  "kind": "freeze",
                  "params": {
                    "days": 7
                  }
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: the vein is frozen for a week."
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
    },
    "seq": [
      "c1",
      "c2"
    ],
    "elseKeys": []
  },
  "_liveSource": "harass_placeholder_conclave.json",
  "_liveHash": "b2654ffb"
}
```

# harass_placeholder — imported from data/events/harass_placeholder.json

```json
{
  "id": "harass_placeholder",
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
          "text": "PROSE-REVIEW placeholder: the lock on your vein has been tampered with. The cameras point at the wall."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: it will stay that way until someone pays.",
          "choices": [
            {
              "label": "Pay to put it right (£100)",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -100
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: you pay. The lock is a lock again."
            },
            {
              "label": "Leave it",
              "effects": [
                {
                  "op": "harassment_add",
                  "kind": "securityDegrade",
                  "params": {
                    "tiers": 1,
                    "cost": 100
                  }
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: you leave it. The vein is easier to get into now."
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
  "_liveSource": "harass_placeholder.json",
  "_liveHash": "83b6897a"
}
```

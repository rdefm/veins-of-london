# harass_placeholder_network — imported from data/events/harass_placeholder_network.json

```json
{
  "id": "harass_placeholder_network",
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
          "text": "PROSE-REVIEW placeholder: the Network has been talking about you, to everyone."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: a retraction can be arranged.",
          "choices": [
            {
              "label": "Pay for a retraction (£100)",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -100
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: the rumour dies."
            },
            {
              "label": "Leave it",
              "effects": [
                {
                  "op": "raise_intel",
                  "amount": 15
                },
                {
                  "op": "harassment_add",
                  "kind": "sellPenalty",
                  "params": {
                    "class": "ore",
                    "mult": 0.85,
                    "days": 7
                  }
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: every faction now knows more about you, and ore buyers offer less."
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
  "_liveSource": "harass_placeholder_network.json",
  "_liveHash": "07040226"
}
```

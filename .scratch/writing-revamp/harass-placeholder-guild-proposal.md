# harass_placeholder_guild — imported from data/events/harass_placeholder_guild.json

```json
{
  "id": "harass_placeholder_guild",
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
          "text": "PROSE-REVIEW placeholder: a Guild inspector has decertified a batch of your goods."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: the stamp can be bought back, or you can sell at a loss.",
          "choices": [
            {
              "label": "Pay the re-inspection fee (£100)",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -100
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: the batch is recertified."
            },
            {
              "label": "Leave it",
              "effects": [
                {
                  "op": "harassment_add",
                  "kind": "sellPenalty",
                  "params": {
                    "class": "item",
                    "mult": 0.8,
                    "days": 7
                  }
                },
                {
                  "op": "harassment_add",
                  "kind": "shopBar",
                  "params": {
                    "factionId": "guild",
                    "days": 7
                  }
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: your goods sell for less and the Guild shop is shut to you for a week."
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
  "_liveSource": "harass_placeholder_guild.json",
  "_liveHash": "26b1877c"
}
```

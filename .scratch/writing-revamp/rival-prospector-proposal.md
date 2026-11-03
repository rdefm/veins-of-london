# rival_prospector — imported from data/events/rival_prospector.json

```json
{
  "id": "rival_prospector",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "any",
    "weight": 1,
    "excludeIfFlag": null,
    "barometerState": null,
    "requireUnclaimedSiteInDistrict": true
  },
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
          "text": "Someone else has clearly had the same idea about this patch of ground, and unlike you, they've brought company."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Rival",
          "text": "\"Friendly notice. We're taking an interest in the good plot round here. A hundred quid says our interest fades. Your call.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "He says \"friendly\" the way people say it right before it stops being true.",
          "choices": [
            {
              "label": "Pay them off (£100)",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -100
                }
              ],
              "result_text": "He pockets it without counting it, which is somehow more insulting than if he had. \"Pleasure doing business,\" he says, in the tone of a man who has never once meant that sentence."
            },
            {
              "label": "Let them have it",
              "effects": [
                {
                  "op": "npc_claim_best_unclaimed_site"
                }
              ],
              "result_text": "You shrug and walk off. By the time you're back, someone else's flag is already in the ground on the best plot going."
            }
          ]
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "London rewards neither generosity nor spite. It just carries on."
        }
      ]
    }
  },
  "_keyOrder": {
    "top": [
      "id",
      "cards",
      "on_complete",
      "deck"
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
    }
  },
  "_liveSource": "rival_prospector.json",
  "_liveHash": "302b6b1d"
}
```

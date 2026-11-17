# city_suit — imported from data/events/city_suit.json

```json
{
  "id": "city_suit",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "city",
    "weight": 1,
    "excludeIfFlag": null,
    "barometerState": null
  },
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "narration",
          "label": "The City",
          "speaker": null,
          "text": "A man in a suit that costs more than your flat buys you a coffee you didn't order, in a café you'd never choose. He introduces himself as \"a friend of a friend\", which in the City means nobody vouches for him."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "The Suit",
          "text": "\"I collect fate-type. Recreationally, you understand. Two hundred up front, I match it eightfold if the numbers land. If they don't — well. Markets.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "He's already got his card reader out.",
          "choices": [
            {
              "label": "Trade (£200)",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -200
                },
                {
                  "op": "chance",
                  "p": 0.5,
                  "on_success": [
                    {
                      "op": "add_ore",
                      "type": "fate",
                      "qty": 8
                    }
                  ],
                  "on_fail": []
                }
              ],
              "result_text": "He taps his card against yours and doesn't blink. The transaction completes with the finality of all City transactions — you'll know how it went when you check your ore."
            },
            {
              "label": "Pass",
              "effects": [],
              "result_text": "\"Suit yourself,\" he says, and you both know exactly which word he chose."
            }
          ]
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "He's gone by the time you check your phone. Some men are only ever passing through."
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
    },
    "seq": [
      "c1",
      "c2",
      "c3",
      "c4"
    ],
    "elseKeys": []
  },
  "_liveSource": "city_suit.json",
  "_liveHash": "c3b6f4ef"
}
```

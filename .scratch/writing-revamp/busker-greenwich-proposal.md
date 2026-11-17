# busker_greenwich — imported from data/events/busker_greenwich.json

```json
{
  "id": "busker_greenwich",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "map"
    }
  ],
  "deck": {
    "district": "greenwich",
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
          "label": "Greenwich Market",
          "speaker": null,
          "text": "By the market, a busker inflates himself explaining the finer points of the zero meridian to a strictly disinterested crowd. He clocks you before you clock him."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Busker",
          "text": "\"You look like someone who deals in the good stuff. I know things - like where some small timers may have stashed some calc. Worth twenty quid to a man who knows how to spend it.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "He's either got something, or he's very good at pretending.",
          "choices": [
            {
              "label": "Give him £20",
              "effects": [
                {
                  "op": "add",
                  "path": "player.cash",
                  "value": -20
                },
                {
                  "op": "add_ore",
                  "type": "time",
                  "qty": 1
                },
                {
                  "op": "set_flag",
                  "flag": "greenwichTipOff",
                  "value": true
                }
              ],
              "result_text": "He pockets the note and taps the side of his nose. \"Bus stop outside the McDonalds. Paving stone next to the bench is loose; lift it up and you'll get a nice surprise\". Funnily, he's telling the truth; there's a small stash of calc. Or more accurately, there WAS a small stash of calc."
            },
            {
              "label": "Keep walking",
              "effects": [],
              "result_text": "You keep walking. He shouts something about the Meridian after you. You don't catch it, and don't ask him to repeat it."
            }
          ]
        },
        {
          "key": "c4",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "Whether or not he was lying, Greenwich feels marginally more interesting than it did five minutes ago."
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
  "_liveSource": "busker_greenwich.json",
  "_liveHash": "9b90bc66"
}
```

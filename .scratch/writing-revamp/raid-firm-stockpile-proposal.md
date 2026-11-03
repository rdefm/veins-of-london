# raid_firm_stockpile

```json
{
  "id": "raid_firm_stockpile",
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "key": "c1",
          "type": "narration",
          "text": "Firm stockpile. Old building, Victorian terrace, converted so many times over the years it's a hodgepodge of different buildings stuck together. The inside looks like it would be a labyrinthine warren. \nThe ground floor has a garage that has the shutters open; you can see some cars up on supports, hear a loud radio, and some chatter inside. \nThere's a small door that leads to stairs going up; there's a man leaning against the wall next to the door, vaping. \nThe property backs onto train tracks, so there's no way to get in through there.",
          "choices": [
            {
              "id": "option1",
              "label": "Check out the garage",
              "result_text": "",
              "goto": {
                "branch": "garage"
              }
            },
            {
              "id": "option2",
              "label": "Go to the door upstairs",
              "result_text": "",
              "goto": {
                "branch": "door"
              }
            }
          ]
        }
      ]
    },
    "garage": {
      "title": "garage",
      "cards": [
        {
          "key": "c2",
          "type": "narration",
          "text": ""
        }
      ]
    },
    "door": {
      "title": "door",
      "cards": [
        {
          "key": "c3",
          "type": "narration",
          "text": ""
        }
      ]
    }
  },
  "_layout": {
    "b:garage": [
      491,
      -259
    ],
    "b:door": [
      500,
      350
    ]
  }
}
```

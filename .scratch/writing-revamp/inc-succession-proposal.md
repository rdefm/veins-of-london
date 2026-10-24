# inc_succession — imported from data/events/inc_succession.json

```json
{
  "id": "inc_succession",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "phone"
    }
  ],
  "start": "main",
  "branches": {
    "main": {
      "title": "Start",
      "cards": [
        {
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: The faction has a new voice. The old one has stepped aside.",
          "key": "c1"
        },
        {
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: Someone should say something to the new one.",
          "choices": [
            {
              "label": "Congratulate them",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: They accept it as their due."
            },
            {
              "label": "Say nothing",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: They notice. They always notice."
            }
          ],
          "key": "c2"
        },
        {
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: London adjusts.",
          "key": "c3"
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
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c2": [
        "type",
        "label",
        "speaker",
        "text",
        "choices"
      ],
      "c3": [
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "inc_succession.json",
  "_liveHash": "38e98f01"
}
```

# col_a1_archie_pry — imported from data/events/col_a1_archie_pry.json

```json
{
  "id": "col_a1_archie_pry",
  "on_complete": [
    {
      "op": "set_screen",
      "screen": "contacts"
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
          "text": "You mention Des. Archie's face does the thing it does, which is nothing at all, quite deliberately."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Archie",
          "text": "\"He's good at ground. Best I know. Leave it there.\""
        },
        {
          "key": "c3",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "He very obviously wants to leave it there.",
          "choices": [
            {
              "id": "leave",
              "label": "Leave it",
              "effects": [],
              "result_text": "You leave it. He looks briefly grateful and then annoyed with himself for looking grateful."
            },
            {
              "id": "push",
              "label": "Push",
              "effects": [
                {
                  "op": "set_flag",
                  "flag": "colA1AskedAboutDebt",
                  "value": true
                },
                {
                  "op": "start_event",
                  "event": "col_a1_archie_pry_debt"
                }
              ],
              "result_text": ""
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
        "text"
      ],
      "c3": [
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
      "c2",
      "c3"
    ],
    "elseKeys": []
  },
  "_liveSource": "col_a1_archie_pry.json",
  "_liveHash": "3b26ce8a"
}
```

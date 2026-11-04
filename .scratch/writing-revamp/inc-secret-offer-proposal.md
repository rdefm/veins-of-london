# inc_secret_offer — imported from data/events/inc_secret_offer.json

```json
{
  "id": "inc_secret_offer",
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
          "key": "c1",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: They've been standing outside for an hour, pretending to read a bus timetable."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: \"There's a vein of ours nobody will miss for a week. Take it. Remember who handed it over.\"",
          "choices": [
            {
              "label": "Take the vein",
              "effects": [
                {
                  "op": "accept_secret_offer"
                }
              ],
              "result_text": "PROSE-REVIEW placeholder: The keys arrive in an envelope. Nobody signs for them."
            },
            {
              "label": "Leave it",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: They nod as if they expected it, and the offer is never mentioned again."
            }
          ]
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: London keeps its own accounts."
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
      ],
      "c3": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "inc_secret_offer.json",
  "_liveHash": "505c4793"
}
```

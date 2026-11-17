# inc_truce_expiring — imported from data/events/inc_truce_expiring.json

```json
{
  "id": "inc_truce_expiring",
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
          "text": "PROSE-REVIEW placeholder: The truce has a few days left and nobody has mentioned it."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: Someone has to bring it up.",
          "choices": [
            {
              "label": "Raise it first",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You bring it up. They were waiting for you to."
            },
            {
              "label": "Let it lapse",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You say nothing. The date comes anyway."
            }
          ]
        },
        {
          "key": "c3",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: London carries on."
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
    },
    "seq": [
      "c1",
      "c2",
      "c3"
    ],
    "elseKeys": []
  },
  "_liveSource": "inc_truce_expiring.json",
  "_liveHash": "fa5990c7"
}
```

# inc_raided_revenge — imported from data/events/inc_raided_revenge.json

```json
{
  "id": "inc_raided_revenge",
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
          "text": "PROSE-REVIEW placeholder: A message arrives with an offer folded into it."
        },
        {
          "key": "c2",
          "type": "choice",
          "label": null,
          "speaker": null,
          "text": "PROSE-REVIEW placeholder: They want you to hit back, and they will point you at the door.",
          "choices": [
            {
              "label": "Take the offer",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You say yes. They tell you where to look."
            },
            {
              "label": "Keep your head down",
              "effects": [],
              "result_text": "PROSE-REVIEW placeholder: You say no. The offer is withdrawn politely."
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
    }
  },
  "_liveSource": "inc_raided_revenge.json",
  "_liveHash": "8ad0ff35"
}
```

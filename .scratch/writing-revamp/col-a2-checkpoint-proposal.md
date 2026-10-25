# col_a2_checkpoint — imported from data/events/col_a2_checkpoint.json

```json
{
  "id": "col_a2_checkpoint",
  "on_complete": [
    {
      "op": "set_flag",
      "flag": "colA2CheckpointSeen",
      "value": true
    },
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
          "text": "Nadia reads it straight off the ledger. Fewer losses this fortnight than the one before. More held than lost. She doesn't round anything up."
        },
        {
          "key": "c2",
          "type": "speaker",
          "label": null,
          "speaker": "Nadia",
          "text": "\"That's what it looks like when we bother. Right — next is whoever's still running on luck. I'll draw up a list.\""
        },
        {
          "key": "c3",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Somebody asks Des if he's happy with it. He takes a second longer than the question needs."
        },
        {
          "key": "c4",
          "type": "speaker",
          "label": null,
          "speaker": "Des",
          "text": "\"It's working.\""
        },
        {
          "key": "c5",
          "type": "narration",
          "label": null,
          "speaker": null,
          "text": "Not quite what he was asked. He lets it go — everyone else is glad, and he isn't sure yet he's right not to be."
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
        "text"
      ],
      "c4": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ],
      "c5": [
        "key",
        "type",
        "label",
        "speaker",
        "text"
      ]
    }
  },
  "_liveSource": "col_a2_checkpoint.json",
  "_liveHash": "369d083f"
}
```

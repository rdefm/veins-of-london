# col_hakim_intel — imported from data/events/col_hakim_intel.json

```json
{
  "id": "col_hakim_intel",
  "on_complete": [
    {
      "op": "reveal_site"
    },
    {
      "op": "set_hakim_intel_day"
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
          "type": "speaker",
          "label": null,
          "speaker": "Hakim",
          "text": "\"Bloke came in for a Lucozade and wouldn't shut up about the yard behind the launderette. Might be nothing. Thought you'd want it before somebody else does.\""
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "It is on your map now. He will not mention it again and will be embarrassed if you thank him twice."
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
      ]
    }
  },
  "_liveSource": "col_hakim_intel.json",
  "_liveHash": "51e44057"
}
```

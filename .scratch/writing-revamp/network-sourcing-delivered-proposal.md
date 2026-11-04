# network_sourcing_delivered — imported from data/events/network_sourcing_delivered.json

```json
{
  "id": "network_sourcing_delivered",
  "on_complete": [
    {
      "op": "reveal_site"
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
          "speaker": "Handler",
          "text": "\"As ordered. Nobody else has it yet. I'd go before that changes.\""
        },
        {
          "key": "c2",
          "type": "resolution",
          "label": null,
          "speaker": null,
          "text": "It is on your map now. The invoice arrived before the text did."
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
  "_liveSource": "network_sourcing_delivered.json",
  "_liveHash": "0e170016"
}
```

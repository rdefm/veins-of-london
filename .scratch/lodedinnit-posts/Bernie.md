# Bernie Kale — LodedInnit posts (DRAFT, awaiting review)

Status: needs-triage. PROSE-REVIEW: every post below.

## Character brief

- Cultivation, life + physics, Lv3 cap 3, wage £420 flat. "Forty years in the trade. Not here to learn." Tea, two sugars, no questions.
- The anti-Gideon: terse, flat, one or two short sentences. No hashtags, no "thrilled", no lessons, no exclamation marks (even under the LodedInnit carve-out), no emoji.
- Core device: he has no reason to be on LodedInnit. He posts only by accident, confusion or grudging obligation, never to share or sell himself.
- No allotments (Marcia's). No Archie. No depots. No cross-comments yet (deferred until every character's personality is defined).
- Plain text, `\n` only inside threads.

## Quirks (approved)

- **C. The mug:** convinced someone is moving/using his mug. Never resolved, never accused by name.
- **D. Sudden stranger praise:** a sincere one-line compliment for a stranger or small kindness, then back to grumbling.
- Quirks pop up occasionally (3 mug posts, 3 praise posts of ~25), they don't define him.

## Feed implementation notes (not yet done)

- Lower author weight than the others (e.g. 0.5) and a smaller voice pool, so he posts rarely.
- **Self-reply field needed** (approved in principle): the mug thread and search-bar thread are Bernie replying to his own post. Canned comments currently only come from other candidates.
- Cross-comments: later. Search-bar replies B1-B5 were written without the commenter lines, so re-check them once those exist.

## Flags

- No invented lore. "Forty years" and "three owners" are canon in `hiring.json`.
- Mug posts imply nothing supernatural. Keep it ordinary.
- "SE15" in the search-bar post is Peckham/Nunhead. Fine for London flavour, but check against any district naming.

## Single posts

### 1
```
Somebody's endorsed me for "synergy". Is that another one of these apps?
```

### 2
```
Lad at work said I should be on here. I'm on here. What now.
```

### 3
```
Pressed a button. It said "Post". Well, that's done.
```

### 4
```
Phone says someone viewed my profile. Hope they try other angles. Left side's my good one.
```

### 5
```
Somebody's asked me to "share my journey". Bus, then Victoria line. Both were late.
```

### 6
```
Someone's written "congrats" under my last post. For what. Nothing happened.
```

### 7
```
Some guy on this app is going on about how his hangnail taught him about overcoming adversity. Don't get it, myself. Mine just hurt.
```

### 8
```
Notification says someone's completed a marathon. Dunno why they're telling me. I don't watch sports.
```

### 9 (quirk D: praise)
```
Woman on the 54 gave up her seat to a wee lad with a cello. Good woman. Anyway, the bus was late.
```

### 10 (quirk D: praise)
```
Bloke down the road fixed a neighbour's gate without being asked. Never got his name. Hope he's well.
```

### 11 (quirk D: praise)
```
Kid in the café got my order right first time. Said nothing. Just got it right. Rare.
```

### 12
```
Asked about my five-year plan. Same as the last eight.
```


## Threads (post + Bernie's own replies; needs self-reply field)

### T1: The mug (quirk C)
Post:
```
Mug's moved again. Nobody's saying anything. Fine.
```
Reply 1:
```
Someone's washed it. That's worse.
```
Reply 2:
```
Found it exactly where I left it. Suspicious in itself.
```

### T2: Search bar
Post (he thinks he's using a search engine):
```
Need a good plumber, SE15. Blocked toilet.
```
Replies, written to work against roasts or help offers from other people:
```
Thanks. First one's a man called Raymond. Do I want Raymond.
```
```
Is this sponsored. I want a good plumber, not an ad.
```
```
I only wanted the one plumber. Not forty opinions.
```
```
Don't recall asking what's wrong with me. Just the plumber.
```


## Removed

- Old 1-5 from `lodedinnit.json` (dropped, per review), plus "Message asking if I'm free" (the "I" post).

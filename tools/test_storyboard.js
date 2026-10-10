// Node test for tools/storyboard.html's draft model (parse/serialise, legacy conversion, play order).
// Run with: node tools/test_storyboard.js
//
// Extracts the pure section straight out of the shipped HTML file (between the two comment markers
// below) so the tests exercise the exact code the browser runs, not a hand-copied duplicate.

const fs = require("fs");
const path = require("path");
const assert = require("assert");

const html = fs.readFileSync(path.join(__dirname, "storyboard.html"), "utf-8");
const startMarker = "/* ---------- Draft model (pure) ---------- */";
const endMarker = "/* ---------- End draft model ---------- */";
const s = html.indexOf(startMarker);
const e = html.indexOf(endMarker);
assert(s !== -1 && e !== -1, "could not locate draft model markers in storyboard.html");
const {
  parseProposal, parseDraft, serialiseDraft, ensureKeys, legacyToDraft, nextPos, playOrder, flatCards, thenText,
  jsonBlockRange, spliceDraft, writableProposal, cardByKey, makeHistory,
  cardPos, insertCard, deleteCard, moveCard, danglingLinks, hasCycle, buildGraph, elkGraph, placeLayout,
  findCycle, addBranch, renameBranch, deleteBranch, inboundLinks, setCardGoto, setThen,
  COND_KINDS, condKind, blankCond, condGet, condSet,
} = new Function(
  html.slice(s, e) +
    "\nreturn { parseProposal, parseDraft, serialiseDraft, ensureKeys, legacyToDraft, nextPos, playOrder, flatCards, thenText," +
    " jsonBlockRange, spliceDraft, writableProposal, cardByKey, makeHistory," +
    " cardPos, insertCard, deleteCard, moveCard, danglingLinks, hasCycle, buildGraph, elkGraph, placeLayout," +
    " findCycle, addBranch, renameBranch, deleteBranch, inboundLinks, setCardGoto, setThen," +
    " COND_KINDS, condKind, blankCond, condGet, condSet };"
)();

let passed = 0;
function test(name, fn) {
  try { fn(); passed++; } catch (err) { console.error("FAIL " + name + "\n  " + err.message); process.exitCode = 1; }
}
const keysOf = (order) => order.map((p) => p.branch + "/" + p.idx);

// A branch draft using every routing form: outcome goto, card goto, single/conditional/"end"/omitted then.
const draftText = JSON.stringify({
  id: "james_meeting",
  at: { block: "evening" },
  start: "main",
  branches: {
    main: { title: "Workshop", cards: [
      { key: "c1", type: "narration", text: "One." },
      { key: "c2", type: "narration", text: "Two.",
        choices: [{ id: "patient", label: "Take your time", checkNote: "steady, ~55% x2",
          check: { base: 0.55, attempts: 2 },
          success: { result_text: "ok", goto: { branch: "after" } },
          fail: { result_text: "no", goto: { branch: "botched" } } }] },
      { key: "c3", type: "speaker", text: "Three.", goto: { branch: "after", card: "c9" } },
    ] },
    botched: { title: "James unimpressed", cards: [{ key: "c4", type: "narration", text: "Botched." }],
      then: [{ if: { flag: "jamesWatching" }, branch: "watched" }, { branch: "after" }] },
    watched: { title: "Watched", cards: [{ key: "c5", type: "narration", text: "Watched." }], then: "end" },
    after: { title: "Wrap-up", cards: [{ key: "c8", type: "narration", text: "A." }, { key: "c9", type: "narration", text: "B." }] },
  },
}, null, 2);

test("branch draft parses as a draft, not legacy", () => {
  const { draft, legacy } = parseDraft(draftText);
  assert.strictEqual(legacy, false);
  assert.deepStrictEqual(Object.keys(draft.branches), ["main", "botched", "watched", "after"]);
});

test("parse → serialise round-trip is lossless", () => {
  const out = serialiseDraft(parseDraft(draftText).draft);
  assert.strictEqual(out, draftText);
  assert.strictEqual(serialiseDraft(parseDraft(out).draft), out);
});

test("ensureKeys fills only missing keys, unique, and is stable on re-parse", () => {
  const d = ensureKeys({ start: "a", branches: {
    a: { cards: [{ text: "x" }, { key: "c1", text: "y" }] },
    b: { cards: [{ text: "z" }, { key: "c3" }, { text: "w" }] },
  } });
  const keys = flatCards(d).map((f) => f.card.key);
  assert.deepStrictEqual(keys, ["c2", "c1", "c4", "c3", "c5"]);
  const again = parseDraft(serialiseDraft(d)).draft;
  assert.deepStrictEqual(flatCards(again).map((f) => f.card.key), keys);
});

test("nextPos: outcome goto beats card order", () => {
  const { draft } = parseDraft(draftText);
  assert.deepStrictEqual(nextPos(draft, { branch: "main", idx: 1 }, { goto: { branch: "botched" } }), { branch: "botched", idx: 0 });
  assert.deepStrictEqual(nextPos(draft, { branch: "main", idx: 1 }, null), { branch: "main", idx: 2 });
});

test("nextPos: card goto with card key", () => {
  const { draft } = parseDraft(draftText);
  assert.deepStrictEqual(nextPos(draft, { branch: "main", idx: 2 }, null), { branch: "after", idx: 1 });
});

test("nextPos: then forms — conditional (else / if), end, omitted", () => {
  const { draft } = parseDraft(draftText);
  assert.deepStrictEqual(nextPos(draft, { branch: "botched", idx: 0 }, null), { branch: "after", idx: 0 });
  const cond = (c) => c.flag === "jamesWatching";
  assert.deepStrictEqual(nextPos(draft, { branch: "botched", idx: 0 }, null, cond), { branch: "watched", idx: 0 });
  assert.strictEqual(nextPos(draft, { branch: "watched", idx: 0 }, null), null);
  assert.strictEqual(nextPos(draft, { branch: "after", idx: 1 }, null), null);
});

test("nextPos: conditional list with no matching entry ends", () => {
  const d = { start: "a", branches: { a: { cards: [{ key: "k" }], then: [{ if: { flag: "x" }, branch: "a" }] } } };
  assert.strictEqual(nextPos(d, { branch: "a", idx: 0 }, null), null);
});

test("nextPos: unknown branch or card key throws", () => {
  const { draft } = parseDraft(draftText);
  assert.throws(() => nextPos(draft, { branch: "main", idx: 0 }, { goto: { branch: "nope" } }), /unknown branch/);
  assert.throws(() => nextPos(draft, { branch: "main", idx: 0 }, { goto: { branch: "after", card: "zz" } }), /no card zz/);
});

test("playOrder follows outcome goto, card goto and then", () => {
  const { draft } = parseDraft(draftText);
  const pickFail = (card) => card.choices[0].fail;
  assert.deepStrictEqual(keysOf(playOrder(draft, pickFail)), ["main/0", "main/1", "botched/0", "after/0", "after/1"]);
  const pickOk = (card) => card.choices[0].success;
  assert.deepStrictEqual(keysOf(playOrder(draft, pickOk)), ["main/0", "main/1", "after/0", "after/1"]);
  assert.deepStrictEqual(keysOf(playOrder(draft, () => null)), ["main/0", "main/1", "main/2", "after/1"]);
  assert.deepStrictEqual(keysOf(playOrder(draft, pickFail, () => true)), ["main/0", "main/1", "botched/0", "watched/0"]);
});

test("playOrder rejects a loop", () => {
  const d = { start: "a", branches: { a: { cards: [{ key: "k" }], then: { branch: "a" } } } };
  assert.throws(() => playOrder(d), /loops/);
});

// Legacy flat event: gotos (0-based card indexes) on a plain option, success/fail and bySuccesses.
const legacy = {
  id: "buyer", at: { block: "evening" },
  cards: [
    { type: "narration", text: "0" },
    { type: "choice", text: "1", choices: [
      { label: "plain", result_text: "p", goto: 4 },
      { label: "roll", check: { base: 0.5 }, success: { result_text: "s", goto: 3 }, fail: { result_text: "f" } },
      { label: "multi", check: { base: 0.5, attempts: 2 }, success: { result_text: "s" }, fail: { result_text: "f" },
        bySuccesses: { 2: { result_text: "two", goto: 5 } } },
    ] },
    { type: "narration", text: "2" },
    { type: "narration", text: "3" },
    { type: "narration", text: "4" },
    { type: "narration", text: "5" },
  ],
};

test("legacy flat event converts to named branches split at goto targets", () => {
  const d = legacyToDraft(legacy);
  assert.strictEqual(d.id, "buyer");
  assert.deepStrictEqual(d.at, { block: "evening" });
  assert.strictEqual(d.cards, undefined);
  assert.strictEqual(d.start, "main");
  assert.deepStrictEqual(Object.keys(d.branches), ["main", "b4", "b5", "b6"]);
  assert.deepStrictEqual(d.branches.main.cards.map((c) => c.key), ["c1", "c2", "c3"]);
  assert.deepStrictEqual(d.branches.main.then, { branch: "b4" });
  assert.deepStrictEqual(d.branches.b5.then, { branch: "b6" });
  assert.strictEqual(d.branches.b6.then, undefined);
  const opts = d.branches.main.cards[1].choices;
  assert.deepStrictEqual(opts[0].goto, { branch: "b5" });
  assert.deepStrictEqual(opts[1].success.goto, { branch: "b4" });
  assert.deepStrictEqual(opts[2].bySuccesses[2].goto, { branch: "b6" });
  assert.strictEqual(legacy.cards[1].choices[0].goto, 4, "source event is not mutated");
});

test("legacy conversion plays the same card order as the flat engine", () => {
  const d = legacyToDraft(legacy);
  const text = (order) => order.map((p) => d.branches[p.branch].cards[p.idx].text);
  assert.deepStrictEqual(text(playOrder(d, (c) => c.choices[0])), ["0", "1", "4", "5"]);
  assert.deepStrictEqual(text(playOrder(d, (c) => c.choices[1].success)), ["0", "1", "3", "4", "5"]);
  assert.deepStrictEqual(text(playOrder(d, (c) => c.choices[1].fail)), ["0", "1", "2", "3", "4", "5"]);
  assert.deepStrictEqual(text(playOrder(d, (c) => c.choices[2].bySuccesses[2])), ["0", "1", "5"]);
});

test("legacy conversion rejects a backwards goto", () => {
  assert.throws(() => legacyToDraft({ id: "x", cards: [{ text: "a" }, { text: "b", choices: [{ label: "l", goto: 0 }] }] }), /not a later card/);
});

test("thenText describes every then form", () => {
  assert.strictEqual(thenText(undefined), "end");
  assert.strictEqual(thenText("end"), "end");
  assert.strictEqual(thenText({ branch: "a", card: "c2" }), "a · c2");
  assert.strictEqual(thenText([{ if: { flag: "f" }, branch: "a" }, { branch: "b" }]), 'if {"flag":"f"}: a; else: b');
});

test("parseProposal: md wrapper, branch draft and legacy", () => {
  const md = (body) => "# Title **x**\n\nThe logline.\n\n```json\n" + body + "\n```\n\n## Open points\n\n- one\n- two\n";
  const b = parseProposal("p.md", md(draftText));
  assert.strictEqual(b.title, "Title x");
  assert.strictEqual(b.logline, "The logline.");
  assert.deepStrictEqual(b.questions, ["one", "two"]);
  assert.strictEqual(b.legacy, false);
  assert.strictEqual(b.draft.id, "james_meeting");
  const l = parseProposal("l.md", md(JSON.stringify(legacy)));
  assert.strictEqual(l.legacy, true);
  assert.strictEqual(l.draft.start, "main");
  assert.match(parseProposal("e.md", md("{ nope")).error, /doesn't parse/);
  assert.match(parseProposal("e.md", md("{}")).error, /neither branches nor a cards array/);
});

// Prose outside the JSON block must survive a save byte-for-byte.
function assertSpliceKeepsProse(md, out) {
  const a = jsonBlockRange(md), b = jsonBlockRange(out);
  assert.strictEqual(out.slice(0, b.start), md.slice(0, a.start), "prose before the block changed");
  assert.strictEqual(out.slice(b.end), md.slice(a.end), "prose after the block changed");
}

test("spliceDraft: edited card text lands in the block; prose before/after byte-identical", () => {
  const md = "# T\n\nLogline, `code` and $1.\n\n```json\n" + draftText + "\n```\n\n## Open points\n\n- $& and $1 stay literal\n";
  const { draft } = parseDraft(draftText);
  cardByKey(draft, "c2").text = "Edited, with $& and a \"quote\".";
  const out = spliceDraft(md, draft);
  assertSpliceKeepsProse(md, out);
  const back = parseProposal("p.md", out).draft;
  assert.strictEqual(cardByKey(back, "c2").text, "Edited, with $& and a \"quote\".");
  assert.strictEqual(spliceDraft(md, parseDraft(draftText).draft), md, "unchanged draft is a no-op");
});

test("spliceDraft keeps CRLF line endings in the block and around it", () => {
  const md = ("# T\n\nIntro.\n\n```json\n" + draftText + "\n```\n\nAfter.\n").replace(/\n/g, "\r\n");
  const { draft } = parseProposal("p.md", md);
  assert.strictEqual(spliceDraft(md, draft), md);
  cardByKey(draft, "c1").text = "New.";
  const out = spliceDraft(md, draft);
  assertSpliceKeepsProse(md, out);
  assert(!/[^\r]\n/.test(out), "a bare LF crept in");
});

test("spliceDraft throws without a JSON block", () => {
  assert.throws(() => spliceDraft("# nothing here\n", { branches: {} }), /no ```json block/);
});

test("writableProposal: only .scratch/writing-revamp, never data/events", () => {
  assert.strictEqual(writableProposal([".scratch", "writing-revamp"]), true);
  assert.strictEqual(writableProposal(["data", "events"]), false);
  assert.strictEqual(writableProposal([".scratch", "writing-revamp", "..", "..", "data", "events"]), false);
});

test("the tool never names data/events as a directory to open or write", () => {
  assert(!/\[\s*["']data["']\s*,\s*["']events["']/.test(html), "storyboard.html references a data/events dir path");
});

test("makeHistory undoes one step at a time and skips duplicate snapshots", () => {
  const { draft } = parseDraft(draftText);
  const h = makeHistory();
  const texts = [];
  for (const t of ["A", "B", "C"]) {
    h.snapshot(serialiseDraft(draft)); h.snapshot(serialiseDraft(draft));
    texts.push(serialiseDraft(draft));
    cardByKey(draft, "c1").text = t;
  }
  assert.strictEqual(h.size, 3);
  for (const want of texts.reverse()) assert.strictEqual(h.undo(), want);
  assert.strictEqual(h.undo(), null);
  assert.strictEqual(cardByKey(parseDraft(texts[texts.length - 1]).draft, "c1").text, "One.");
});

test("cardByKey finds cards across branches, null when missing", () => {
  const { draft } = parseDraft(draftText);
  assert.strictEqual(cardByKey(draft, "c9").text, "B.");
  assert.strictEqual(cardByKey(draft, "zz"), null);
});

const keysIn = (d, b) => d.branches[b].cards.map((c) => c.key);

test("insertCard: blank narration with a fresh key, before / after / at end", () => {
  const { draft } = parseDraft(draftText);
  const k1 = insertCard(draft, "after", 0);
  const k2 = insertCard(draft, "after", 99);
  assert.deepStrictEqual(keysIn(draft, "after"), [k1, "c8", "c9", k2]);
  assert.notStrictEqual(k1, k2);
  assert.strictEqual(new Set(flatCards(draft).map((f) => f.card.key)).size, flatCards(draft).length);
  assert.deepStrictEqual(cardByKey(draft, k1), { key: k1, type: "narration", text: "" });
  assert.throws(() => insertCard(draft, "nope", 0), /unknown branch/);
});

test("links to a card survive insert and reorder", () => {
  const { draft } = parseDraft(draftText);
  // main/c3 jumps to after/c9 by key.
  insertCard(draft, "after", 0);
  moveCard(draft, "c9", -1);
  moveCard(draft, "c9", -1);
  assert.deepStrictEqual(keysIn(draft, "after").slice(0, 1), ["c9"]);
  const to = nextPos(draft, cardPos(draft, "c3"), null);
  assert.strictEqual(draft.branches[to.branch].cards[to.idx].key, "c9");
  const played = playOrder(draft, () => null).map((p) => draft.branches[p.branch].cards[p.idx].key);
  assert.deepStrictEqual(played.slice(0, 4), ["c1", "c2", "c3", "c9"]);
});

test("moveCard refuses past the branch edge and leaves the draft unchanged", () => {
  const { draft } = parseDraft(draftText);
  const before = serialiseDraft(draft);
  assert.throws(() => moveCard(draft, "c1", -1), /end of its branch/);
  assert.throws(() => moveCard(draft, "c3", 1), /end of its branch/);
  assert.strictEqual(serialiseDraft(draft), before);
});

test("moveCard refuses an order that loops", () => {
  // a1 jumps to a3; moving a3 above a1 would make a3 → a1 → a3.
  const d = { start: "a", branches: { a: { cards: [
    { key: "a1", goto: { branch: "a", card: "a3" } }, { key: "a2" }, { key: "a3" }] } } };
  assert.strictEqual(hasCycle(d), false);
  moveCard(d, "a3", -1);
  assert.deepStrictEqual(keysIn(d, "a"), ["a1", "a3", "a2"]);
  const before = serialiseDraft(d);
  assert.throws(() => moveCard(d, "a3", -1), /loop/);
  assert.strictEqual(serialiseDraft(d), before);
});

test("hasCycle follows outcomes, card gotos and every then entry", () => {
  const { draft } = parseDraft(draftText);
  assert.strictEqual(hasCycle(draft), false);
  draft.branches.after.then = [{ if: { flag: "x" }, branch: "main" }, { branch: "watched" }];
  assert.strictEqual(hasCycle(draft), true);
});

test("deleting a linked-to card lists the dangling links", () => {
  const { draft } = parseDraft(draftText);
  assert.deepStrictEqual(danglingLinks(draft, "c8"), []);
  const d9 = danglingLinks(draft, "c9");
  assert.deepStrictEqual(d9.map((l) => l.from), ["main · c3"]);
  // botched's only card: the fail outcome and nothing else names branch botched.
  const d4 = danglingLinks(draft, "c4");
  assert.deepStrictEqual(d4.map((l) => l.from), ['main · c2 · option "patient" fail']);
  // watched's only card is named by botched's conditional then.
  assert.deepStrictEqual(danglingLinks(draft, "c5").map((l) => l.from), ["botched · then"]);
  // A card's own links leave with it.
  assert.deepStrictEqual(danglingLinks(draft, "c2"), []);
  deleteCard(draft, "c9");
  assert.deepStrictEqual(keysIn(draft, "after"), ["c8"]);
  assert.throws(() => nextPos(draft, cardPos(draft, "c3"), null), /no card c9/);
});

test("deleteCard refuses to empty the start branch", () => {
  const d = { start: "a", branches: { a: { cards: [{ key: "k" }] } } };
  assert.throws(() => deleteCard(d, "k"), /start branch/);
  assert.throws(() => deleteCard(d, "zz"), /no card zz/);
});

test("card CRUD is undoable through history and saves into the block", () => {
  const md = "# T\n\nIntro.\n\n```json\n" + draftText + "\n```\n\nAfter.\n";
  const { draft } = parseProposal("p.md", md);
  const h = makeHistory();
  const orig = serialiseDraft(draft);
  h.snapshot(serialiseDraft(draft)); const k = insertCard(draft, "main", 1);
  Object.assign(cardByKey(draft, k), { type: "speaker", speaker: "James", label: "Later", text: "Hi." });
  h.snapshot(serialiseDraft(draft)); moveCard(draft, "c1", 1);
  h.snapshot(serialiseDraft(draft)); deleteCard(draft, "c8");
  const out = spliceDraft(md, draft);
  assertSpliceKeepsProse(md, out);
  const back = parseProposal("p.md", out).draft;
  assert.deepStrictEqual(keysIn(back, "main"), [k, "c1", "c2", "c3"]);
  assert.deepStrictEqual(cardByKey(back, k), { key: k, type: "speaker", text: "Hi.", speaker: "James", label: "Later" });
  assert.deepStrictEqual(keysIn(back, "after"), ["c9"]);
  assert.strictEqual(h.size, 3);
  h.undo(); h.undo();
  assert.strictEqual(h.undo(), orig);
});

// Every real writing proposal converts and plays to an end along every first-option path.
const propDir = path.join(__dirname, "..", ".scratch", "writing-revamp");
const proposals = fs.existsSync(propDir) ? fs.readdirSync(propDir).filter((f) => /-proposal.*\.md$/.test(f)) : [];
for (const f of proposals) {
  test("writing proposal converts: " + f, () => {
    const b = parseProposal(f, fs.readFileSync(path.join(propDir, f), "utf-8"));
    assert(b, "no JSON block");
    assert.strictEqual(b.error, undefined, b.error);
    const keys = flatCards(b.draft).map((x) => x.card.key);
    assert.strictEqual(new Set(keys).size, keys.length, "duplicate card keys");
    const first = (card) => { const o = card.choices[0]; return o.check ? o.success : o; };
    assert(playOrder(b.draft, first).length > 0);
    assert.strictEqual(hasCycle(b.draft), false, "card graph loops");
  });
  test("writing proposal saves without touching prose: " + f, () => {
    const md = fs.readFileSync(path.join(propDir, f), "utf-8");
    const { draft } = parseProposal(f, md);
    const card = flatCards(draft)[0].card;
    card.text = (card.text || "") + " (edited)";
    const out = spliceDraft(md, draft);
    assertSpliceKeepsProse(md, out);
    assert.strictEqual(flatCards(parseProposal(f, out).draft)[0].card.text, card.text);
  });
}

// ---- flowchart graph -------------------------------------------------------
const edgeList = (g) => g.edges.map((e) => `${e.from} > ${e.to} [${e.kind}] ${e.label}`.trim());

test("buildGraph collapsed: one node per branch, outcome / card goto / then edges, end node", () => {
  const { draft } = parseDraft(draftText);
  const g = buildGraph(draft);
  assert.deepStrictEqual(g.nodes.map((n) => n.id), ["b:main", "b:botched", "b:watched", "b:after", "end"]);
  const main = g.nodes[0];
  assert.deepStrictEqual([main.kind, main.title, main.count, main.first, main.start], ["branch", "Workshop", 3, "One.", true]);
  assert.strictEqual(g.nodes[1].start, false);
  assert.deepStrictEqual(edgeList(g), [
    "b:main > b:after [outcome] Take your time ✓",
    "b:main > b:botched [outcome] Take your time ✗",
    "b:main > b:after [goto] · c9",
    "b:botched > b:watched [then] if flag jamesWatching",
    "b:botched > b:after [then] else",
    "b:watched > end [then]",
    "b:after > end [then]",
  ]);
  assert.strictEqual(new Set(g.edges.map((e) => e.id)).size, g.edges.length);
});

test("buildGraph expanded: cards nest in their branch frame, fall-through edges, dead fall-through omitted", () => {
  const { draft } = parseDraft(draftText);
  const g = buildGraph(draft, Object.keys(draft.branches));
  assert.deepStrictEqual(g.nodes.map((n) => n.id + (n.parent ? "<" + n.parent : "")), [
    "g:main", "c:c1<g:main", "c:c2<g:main", "c:c3<g:main", "g:botched", "c:c4<g:botched",
    "g:watched", "c:c5<g:watched", "g:after", "c:c8<g:after", "c:c9<g:after", "end"]);
  const c2 = g.nodes.find((n) => n.id === "c:c2");
  assert.deepStrictEqual([c2.kind, c2.type, c2.text, c2.choices, c2.start], ["card", "narration", "Two.", 1, false]);
  assert.strictEqual(g.nodes.find((n) => n.id === "c:c1").start, true);
  // c2's option routes every outcome, so there is no c2 → c3 fall-through; c3's card goto skips main's then.
  assert.deepStrictEqual(edgeList(g), [
    "c:c1 > c:c2 [next]",
    "c:c2 > c:c8 [outcome] Take your time ✓",
    "c:c2 > c:c4 [outcome] Take your time ✗",
    "c:c3 > c:c9 [goto]",
    "c:c4 > c:c5 [then] if flag jamesWatching",
    "c:c4 > c:c8 [then] else",
    "c:c5 > end [then]",
    "c:c8 > c:c9 [next]",
    "c:c9 > end [then]",
  ]);
});

test("buildGraph expands one branch inline; links into it land on its cards", () => {
  const { draft } = parseDraft(draftText);
  const g = buildGraph(draft, ["after"]);
  assert.deepStrictEqual(g.nodes.map((n) => n.id), ["b:main", "b:botched", "b:watched", "g:after", "c:c8", "c:c9", "end"]);
  assert.deepStrictEqual(edgeList(g), [
    "b:main > c:c8 [outcome] Take your time ✓",
    "b:main > b:botched [outcome] Take your time ✗",
    "b:main > c:c9 [goto]",
    "b:botched > b:watched [then] if flag jamesWatching",
    "b:botched > c:c8 [then] else",
    "b:watched > end [then]",
    "c:c8 > c:c9 [next]",
    "c:c9 > end [then]",
  ]);
});

test("buildGraph: bySuccesses edges, no else = edge to end, dangling and same-branch links dropped, empty branch", () => {
  const draft = ensureKeys({ start: "a", branches: {
    a: { title: "A", cards: [
      { text: "x", choices: [{ label: "Try", check: { base: 0.5, attempts: 2 },
        success: { goto: { branch: "b" } }, fail: {}, bySuccesses: { 2: { goto: { branch: "c" } } } }] },
      { text: "y", goto: { branch: "a", card: "c3" } },
      { text: "z", goto: { branch: "ghost" } },
    ], then: [{ if: { flag: "f" }, branch: "b" }] },
    b: { cards: [{ text: "b1" }], then: { branch: "c" } },
    c: { title: "Empty", cards: [] },
  } });
  const collapsed = buildGraph(draft);
  assert.deepStrictEqual(edgeList(collapsed), [
    "b:a > b:b [outcome] Try ✓",
    "b:a > b:c [outcome] Try 2✓",
    "b:b > b:c [then]",
    "b:c > end [then]",
  ]);
  // Card c3's goto to a missing branch leaves no edge and no fall-through, so a's conditional then is dead.
  const open = buildGraph(draft, ["a", "b", "c"]);
  assert(open.nodes.some((n) => n.id === "b:c" && n.kind === "branch" && n.count === 0), "empty branch stays a branch node");
  assert.deepStrictEqual(edgeList(open), [
    "c:c1 > c:c4 [outcome] Try ✓",
    "c:c1 > b:c [outcome] Try 2✓",
    "c:c1 > c:c2 [next]",
    "c:c2 > c:c3 [goto]",
    "c:c4 > b:c [then]",
    "b:c > end [then]",
  ]);
  // A conditional then with no else entry also routes to the end.
  delete draft.branches.a.cards[2].goto;
  assert.deepStrictEqual(edgeList(buildGraph(draft)).filter((s) => s.includes("[then]") && s.startsWith("b:a")),
    ["b:a > b:b [then] if flag f", "b:a > end [then] else"]);
});

test("elkGraph nests cards in their frame and sizes labels; placeLayout makes geometry absolute", () => {
  const { draft } = parseDraft(draftText);
  const elk = elkGraph(buildGraph(draft, ["after"]));
  assert.strictEqual(elk.layoutOptions["elk.direction"], "RIGHT");
  const frame = elk.children.find((c) => c.id === "g:after");
  assert.deepStrictEqual(frame.children.map((c) => c.id), ["c:c8", "c:c9"]);
  assert(elk.children.every((c) => c.children || (c.width > 0 && c.height > 0)));
  assert.strictEqual(elk.edges.length, 8);
  assert.strictEqual(elk.edges[0].labels[0].text, "Take your time ✓");
  assert.deepStrictEqual(elk.edges[2].labels, []);
  // Shape of a real elkjs 0.9.3 result: children relative to parent, edges relative to their container.
  const L = placeLayout({ id: "root", x: 0, y: 0, width: 699, height: 125,
    children: [{ id: "b:main", x: 12, y: 47, width: 200, height: 60 },
      { id: "g:after", x: 287, y: 12, width: 400, height: 101, children: [
        { id: "c:c8", x: 10, y: 30, width: 180, height: 50 }, { id: "c:c9", x: 210, y: 38, width: 180, height: 50 }] }],
    edges: [
      { id: "e1", container: "root", labels: [{ text: "ok", x: 232, y: 50, width: 30, height: 14 }],
        sections: [{ startPoint: { x: 212, y: 67 }, endPoint: { x: 297, y: 67 } }] },
      { id: "e2", container: "g:after", sections: [{ startPoint: { x: 190, y: 55 }, bendPoints: [{ x: 200, y: 55 }], endPoint: { x: 210, y: 63 } }] }] });
  assert.deepStrictEqual(L.boxes.get("c:c8"), { x: 297, y: 42, w: 180, h: 50 });
  assert(!L.boxes.has("root"));
  assert.deepStrictEqual(L.edges.get("e1").label, { x: 232, y: 50, w: 30, h: 14, text: "ok" });
  assert.deepStrictEqual(L.edges.get("e2").points, [[477, 67], [487, 67], [497, 75]]);
  assert.strictEqual(L.edges.get("e2").label, null);
});

// ---- branch routing editing ------------------------------------------------
test("addBranch: new branch with one blank card, after the others; bad or taken names refused", () => {
  const { draft } = parseDraft(draftText);
  const k = addBranch(draft, "late_night", "Late night");
  assert.deepStrictEqual(Object.keys(draft.branches).slice(-1), ["late_night"]);
  assert.deepStrictEqual(draft.branches.late_night, { title: "Late night", cards: [{ key: k, type: "narration", text: "" }] });
  assert.strictEqual(new Set(flatCards(draft).map((f) => f.card.key)).size, flatCards(draft).length);
  const before = serialiseDraft(draft);
  assert.throws(() => addBranch(draft, "after"), /already/);
  assert.throws(() => addBranch(draft, "two words"), /letters, digits/);
  assert.throws(() => addBranch(draft, ""), /letters, digits/);
  assert.strictEqual(serialiseDraft(draft), before);
});

test("renameBranch rewrites every link and start, keeps branch order", () => {
  const { draft } = parseDraft(draftText);
  renameBranch(draft, "after", "wrap");
  renameBranch(draft, "main", "workshop");
  assert.deepStrictEqual(Object.keys(draft.branches), ["workshop", "botched", "watched", "wrap"]);
  assert.strictEqual(draft.start, "workshop");
  const c2 = cardByKey(draft, "c2").choices[0];
  assert.deepStrictEqual(c2.success.goto, { branch: "wrap" });
  assert.deepStrictEqual(cardByKey(draft, "c3").goto, { branch: "wrap", card: "c9" });
  assert.deepStrictEqual(draft.branches.botched.then, [{ if: { flag: "jamesWatching" }, branch: "watched" }, { branch: "wrap" }]);
  assert.deepStrictEqual(keysOf(playOrder(draft, () => null)), ["workshop/0", "workshop/1", "workshop/2", "wrap/1"]);
  assert.throws(() => renameBranch(draft, "wrap", "botched"), /already/);
  assert.throws(() => renameBranch(draft, "nope", "x"), /unknown branch/);
  assert.throws(() => renameBranch(draft, "wrap", "a-b"), /letters, digits/);
  renameBranch(draft, "wrap", "wrap");
});

test("inboundLinks lists links into a branch from elsewhere; deleteBranch removes it, refuses start", () => {
  const { draft } = parseDraft(draftText);
  assert.deepStrictEqual(inboundLinks(draft, "after").map((l) => l.from),
    ['main · c2 · option "patient" success', "main · c3", "botched · then"]);
  assert.deepStrictEqual(inboundLinks(draft, "main"), []);
  // A branch's links into itself don't count.
  draft.branches.after.cards[0].goto = { branch: "after", card: "c9" };
  assert.strictEqual(inboundLinks(draft, "after").length, 3);
  deleteBranch(draft, "watched");
  assert.deepStrictEqual(Object.keys(draft.branches), ["main", "botched", "after"]);
  assert.throws(() => deleteBranch(draft, "main"), /start branch/);
  assert.throws(() => deleteBranch(draft, "nope"), /unknown branch/);
});

test("setCardGoto sets, clears and validates a card's goto", () => {
  const { draft } = parseDraft(draftText);
  setCardGoto(draft, "c1", { branch: "after", card: "c9" });
  assert.deepStrictEqual(cardByKey(draft, "c1").goto, { branch: "after", card: "c9" });
  setCardGoto(draft, "c1", { branch: "botched", card: null });
  assert.deepStrictEqual(cardByKey(draft, "c1").goto, { branch: "botched" });
  setCardGoto(draft, "c1", null);
  assert.strictEqual("goto" in cardByKey(draft, "c1"), false);
  assert.throws(() => setCardGoto(draft, "c1", { branch: "nope" }), /unknown branch/);
  assert.throws(() => setCardGoto(draft, "c1", { branch: "after", card: "c1" }), /no card c1 in branch after/);
  assert.throws(() => setCardGoto(draft, "zz", null), /no card zz/);
});

test("a cycle-creating card goto is refused with the loop spelled out; draft unchanged", () => {
  const { draft } = parseDraft(draftText);
  const before = serialiseDraft(draft);
  assert.throws(() => setCardGoto(draft, "c9", { branch: "main" }), /would loop: (\w+ · c\d+ → )+\w+ · c\d+/);
  assert.throws(() => setCardGoto(draft, "c1", { branch: "main", card: "c1" }), /would loop: main · c1 → main · c1/);
  assert.strictEqual(serialiseDraft(draft), before);
});

test("a draft that already loops still takes link edits (one may be the fix)", () => {
  const { draft } = parseDraft(draftText);
  draft.branches.after.then = { branch: "botched" };
  setCardGoto(draft, "c1", { branch: "watched" });
  setThen(draft, "after", "end");
  assert.strictEqual(hasCycle(draft), false);
});

test("findCycle returns the looping card keys, null when acyclic", () => {
  const { draft } = parseDraft(draftText);
  assert.strictEqual(findCycle(draft), null);
  draft.branches.after.then = { branch: "botched" };
  const loop = findCycle(draft);
  assert.strictEqual(loop[0], loop.at(-1));
  assert(loop.includes("c4") && loop.includes("c9"), loop.join(","));
});

test("setThen: single, end, omitted and conditional forms", () => {
  const { draft } = parseDraft(draftText);
  setThen(draft, "after", { branch: "watched", card: null });
  assert.deepStrictEqual(draft.branches.after.then, { branch: "watched" });
  setThen(draft, "after", "end");
  assert.strictEqual(draft.branches.after.then, "end");
  setThen(draft, "after", undefined);
  assert.strictEqual("then" in draft.branches.after, false);
  setThen(draft, "after", [{ if: { cash: { atLeast: 50 } }, branch: "watched", card: null }, { if: { flag: "x" } }, { branch: "watched", card: "c5" }]);
  assert.deepStrictEqual(draft.branches.after.then,
    [{ if: { cash: { atLeast: 50 } }, branch: "watched" }, { if: { flag: "x" } }, { branch: "watched", card: "c5" }]);
  assert.strictEqual(thenText(draft.branches.after.then), 'if {"cash":{"atLeast":50}}: watched; if {"flag":"x"}: end; else: watched · c5');
});

test("setThen refuses unknown targets, a misplaced else and loops; draft unchanged", () => {
  const { draft } = parseDraft(draftText);
  const before = serialiseDraft(draft);
  assert.throws(() => setThen(draft, "nope", "end"), /unknown branch/);
  assert.throws(() => setThen(draft, "after", { branch: "ghost" }), /unknown branch/);
  assert.throws(() => setThen(draft, "after", [{ branch: "watched" }, { if: { flag: "x" }, branch: "watched" }]), /else.*last/);
  assert.throws(() => setThen(draft, "after", "sideways"), /then/);
  assert.throws(() => setThen(draft, "after", [{ if: { flag: "x" }, branch: "main" }]), /would loop/);
  assert.throws(() => setThen(draft, "botched", { branch: "botched" }), /would loop: botched · c4 → botched · c4/);
  assert.strictEqual(serialiseDraft(draft), before);
});

test("a then that can't be reached (last card has its own goto) may point anywhere", () => {
  const { draft } = parseDraft(draftText);
  // With after's last card c9 jumping by its own goto, after's then is dead and can't loop.
  setCardGoto(draft, "c9", { branch: "watched" });
  setThen(draft, "after", { branch: "after" });
  assert.deepStrictEqual(draft.branches.after.then, { branch: "after" });
  // Clearing that goto would bring the dead then to life: refused.
  assert.throws(() => setCardGoto(draft, "c9", null), /would loop: after · c8 → after · c9 → after · c8/);
});

test("COND_KINDS covers condition_met's vocabulary; condKind / blankCond / condGet / condSet", () => {
  assert.deepStrictEqual(Object.keys(COND_KINDS), ["flag", "relation", "cash", "item", "path", "choice"]);
  for (const k of Object.keys(COND_KINDS)) assert.strictEqual(condKind(blankCond(k)), k);
  assert.deepStrictEqual(blankCond("cash"), { cash: { atLeast: 0 } });
  assert.deepStrictEqual(blankCond("choice"), { choice: { event: "", card: 0, option: "" } });
  assert.deepStrictEqual(blankCond("item"), { item: "" });
  assert.strictEqual(condKind({ item: "torch", flag: "f" }), "item", "engine checks item before flag");
  assert.strictEqual(condKind({ nonsense: 1 }), null);
  const c = blankCond("relation");
  condSet(c, "relation", "james"); condSet(c, "atLeast", 3);
  assert.deepStrictEqual(c, { relation: "james", atLeast: 3 });
  const ch = blankCond("choice");
  condSet(ch, "choice.option", "patient");
  assert.strictEqual(condGet(ch, "choice.option"), "patient");
  const it = blankCond("item");
  condSet(it, "equipped", true); assert.deepStrictEqual(it, { item: "", equipped: true });
  condSet(it, "equipped", false); assert.deepStrictEqual(it, { item: "" });
});

test("branch routing edits are undoable through history and save into the block", () => {
  const md = "# T\n\nIntro.\n\n```json\n" + draftText + "\n```\n\nAfter.\n";
  const { draft } = parseProposal("p.md", md);
  const h = makeHistory(), orig = serialiseDraft(draft);
  h.snapshot(serialiseDraft(draft)); addBranch(draft, "coda", "Coda");
  h.snapshot(serialiseDraft(draft)); setThen(draft, "after", [{ if: blankCond("flag"), branch: "coda" }]);
  h.snapshot(serialiseDraft(draft)); setCardGoto(draft, "c1", { branch: "botched" });
  h.snapshot(serialiseDraft(draft)); renameBranch(draft, "botched", "oops");
  const back = parseProposal("p.md", spliceDraft(md, draft)).draft;
  assert.deepStrictEqual(back.branches.after.then, [{ if: { flag: "" }, branch: "coda" }]);
  assert.deepStrictEqual(cardByKey(back, "c1").goto, { branch: "oops" });
  assert.strictEqual(h.size, 4);
  h.undo(); h.undo(); h.undo();
  assert.strictEqual(h.undo(), orig);
});

console.log(`${passed} passed${process.exitCode ? ", some FAILED" : ""}`);

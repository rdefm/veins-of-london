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
} = new Function(
  html.slice(s, e) +
    "\nreturn { parseProposal, parseDraft, serialiseDraft, ensureKeys, legacyToDraft, nextPos, playOrder, flatCards, thenText," +
    " jsonBlockRange, spliceDraft, writableProposal, cardByKey, makeHistory };"
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

console.log(`${passed} passed${process.exitCode ? ", some FAILED" : ""}`);

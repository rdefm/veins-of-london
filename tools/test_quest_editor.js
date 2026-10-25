// Node test for the quest editors' shared mechanics section and the mobile draft bundle.
// Run with: node tools/test_quest_editor.js
//
// Extracts pure functions straight out of the shipped HTML files (between comment
// markers) so the tests always exercise the exact code the browser runs.

const fs = require("fs");
const path = require("path");
const assert = require("assert");

// The option/event mechanics section the mobile editor and the storyboard tool share.
const sharedStartMarker = "/* ---------- Choice mechanics (shared) ---------- */";
const sharedEndMarker = "/* ---------- End choice mechanics ---------- */";
function sharedSection(source, label) {
  const s = source.indexOf(sharedStartMarker);
  const e = source.indexOf(sharedEndMarker);
  assert(s !== -1 && e !== -1, "could not locate shared mechanics markers in " + label);
  return source.slice(s, e + sharedEndMarker.length);
}

const mobilePath = path.join(__dirname, "quest-editor-mobile.html");
const mobileHtml = fs.readFileSync(mobilePath, "utf-8");
const sharedSource = sharedSection(mobileHtml, "quest-editor-mobile.html");
const {
  optionToCheck,
  optionToPlain,
  setConditionKind,
  conditionKind,
  deepClone,
  advanceRule,
  setAdvanceRule,
  setOptionExit,
} = new Function(
  sharedSource +
    "\nreturn { optionToCheck, optionToPlain, setConditionKind, conditionKind, deepClone, advanceRule, setAdvanceRule, setOptionExit };"
)();

let passed = 0;

function test(name, fn) {
  try {
    fn();
    passed++;
    console.log("ok - " + name);
  } catch (err) {
    console.error("FAIL - " + name);
    console.error(err);
    process.exitCode = 1;
  }
}

const eventsDir = path.join(__dirname, "..", "data", "events");
const files = fs.readdirSync(eventsDir).filter((f) => f.endsWith(".json"));
assert(files.length > 0, "expected quest fixtures under data/events/");
/* ---------- Checks, gating, branches and timing (opening-choices 10) ---------- */

const bundleStartMarker = "/* ---------- Draft bundle ---------- */";
const bundleEndMarker = "/* ---------- State ---------- */";
const mbStart = mobileHtml.indexOf(bundleStartMarker);
const mbEnd = mobileHtml.indexOf(bundleEndMarker);
assert(mbStart !== -1 && mbEnd !== -1, "could not locate draft-bundle markers in quest-editor-mobile.html");
const mobile = new Function(
  sharedSection(mobileHtml, "quest-editor-mobile.html") +
    mobileHtml.slice(mbStart, mbEnd) +
    "\nreturn { draftFromParsed, buildBundle, defaultChoice };"
)();

// Every REFERENCE §3.9a/§3.9b field: option id, check with each mod type,
// min/max/show/attempts, success/fail outcomes with goto, requires with
// display + reason, plain-option goto, bySuccesses/perSuccess, event `at`.
const ALL_FIELDS_EVENT = {
  id: "all_fields_fixture",
  at: { block: "evening", advance: true },
  cards: [
    { type: "narration", label: "{today}", speaker: null, text: "It starts." },
    {
      type: "choice",
      label: null,
      speaker: null,
      text: "Pick one.",
      choices: [
        {
          label: "Talk him down",
          id: "talk",
          requires: { flag: "metJames", display: "disable", reason: "You don't know him yet." },
          effects: [{ op: "add", path: "player.cash", value: -5 }],
          check: {
            base: 0.4,
            mods: [
              { flag: "metJames", add: 0.1, label: "You know him" },
              { choice: { event: "intro", card: 3, option: "ask" }, add: 0.05, label: "You asked" },
              { choice: { event: "intro", card: 3, option: 1 }, add: -0.05, label: "You walked off" },
              { path: "player.level", perPoint: 0.02, above: 1, label: "Experience" },
              { relation: "james", atLeast: 2, add: 0.1, label: "He likes you" },
              { cash: { atLeast: 100 }, add: 0.05, label: "Flush" },
              { item: "knuckleduster", add: 0.05, label: "Held" },
              { item: "knuckleduster", equipped: true, add: 0.1, label: "Equipped" },
              { item: "timePearl", optional: true, consume: true, add: 0.2, label: "Pearl" },
            ],
            min: 0.1,
            max: 0.9,
            attempts: 2,
            perSuccess: [{ op: "add", path: "player.cash", value: 10 }],
          },
          success: { result_text: "He backs off.", effects: [], goto: 3 },
          fail: { result_text: "He doesn't.", effects: [{ op: "set_flag", flag: "jamesAngry", value: true }] },
          bySuccesses: { 2: { result_text: "Both land.", effects: [], goto: 3 } },
        },
        {
          label: "Leave",
          requires: { cash: { atLeast: 50 } },
          effects: [],
          result_text: "You go.",
          goto: 3,
        },
        { label: "Hold", requires: { path: "player.level", atLeast: 2 }, effects: [], result_text: "You hold." },
        { label: "Call", requires: { relation: "james", atLeast: 1 }, effects: [], result_text: "You call." },
        { label: "Show", requires: { item: "knuckleduster", equipped: true }, effects: [], result_text: "You show." },
        { label: "Flash", requires: { item: "knuckleduster" }, effects: [], result_text: "You flash." },
        {
          label: "Remind",
          requires: { choice: { event: "intro", card: 3, option: "ask" }, display: "hide" },
          effects: [],
          result_text: "You remind.",
        },
      ],
    },
    { type: "resolution", label: null, speaker: null, text: "Skipped." },
    { type: "resolution", label: null, speaker: null, text: "Landed." },
  ],
  on_complete: [{ op: "set_screen", screen: "map" }],
};

test("the shared mechanics section is byte-identical in the mobile editor and the storyboard tool", () => {
  const storyboardHtml = fs.readFileSync(path.join(__dirname, "storyboard.html"), "utf-8");
  assert.strictEqual(sharedSection(storyboardHtml, "storyboard.html"), sharedSource);
});

test("setConditionKind / conditionKind agree for every condition kind", () => {
  for (const kind of ["flag", "choice", "path", "relation", "cash", "item", "itemEquipped", "itemOptional"]) {
    const mod = {};
    setConditionKind(mod, kind, true);
    assert.strictEqual(conditionKind(mod), kind);
  }
});


test("optionToCheck / optionToPlain carry result_text, goto and effects across the switch", () => {
  const opt = { label: "Go", effects: [{ op: "set_flag", flag: "a", value: true }], result_text: "Gone.", goto: 4 };
  optionToCheck(opt);
  assert.deepStrictEqual(opt, {
    label: "Go",
    effects: [{ op: "set_flag", flag: "a", value: true }],
    check: { base: 0.5, mods: [] },
    success: { result_text: "Gone.", effects: [], goto: 4 },
    fail: { result_text: null, effects: [] },
  });
  optionToPlain(opt);
  assert.deepStrictEqual(opt, { label: "Go", effects: [{ op: "set_flag", flag: "a", value: true }], result_text: "Gone.", goto: 4 });
});

test("setConditionKind keeps a mod's add/label and a requirement's display/reason", () => {
  const mod = { flag: "x", add: 0.2, label: "L" };
  setConditionKind(mod, "relation", true);
  assert.deepStrictEqual(mod, { relation: "", atLeast: 0, add: 0.2, label: "L" });
  setConditionKind(mod, "path", true);
  assert.deepStrictEqual(mod, { path: "", perPoint: 0, label: "L" });
  const req = { flag: "x", display: "disable", reason: "R" };
  setConditionKind(req, "item", false);
  assert.deepStrictEqual(req, { item: "", display: "disable", reason: "R" });
});

test("mobile: a quest with every new field round-trips through a draft without loss", () => {
  const draft = mobile.draftFromParsed(deepClone(ALL_FIELDS_EVENT));
  const bundle = mobile.buildBundle(draft);
  assert.deepStrictEqual(bundle.at, ALL_FIELDS_EVENT.at);
  assert.deepStrictEqual(bundle.cards, ALL_FIELDS_EVENT.cards);
  // ...and the saved bundle reopens to the same bundle.
  const again = mobile.buildBundle(mobile.draftFromParsed(JSON.parse(JSON.stringify(bundle))));
  assert.deepStrictEqual(again.cards, bundle.cards);
  assert.deepStrictEqual(again.at, bundle.at);
  assert.strictEqual(again.notes, bundle.notes);
});

// The mobile editor trims prose and writes blank prose as null (its normProse
// convention), so legacy prose comes back normalized; everything else is exact.
const PROSE_KEYS = ["label", "speaker", "text", "result_text"];
function blankProseToNull(v) {
  if (Array.isArray(v)) return v.map(blankProseToNull);
  if (!v || typeof v !== "object") return v;
  const out = {};
  for (const [k, x] of Object.entries(v)) {
    out[k] = PROSE_KEYS.includes(k) && typeof x === "string" ? x.trim() || null : blankProseToNull(x);
  }
  return out;
}

test("mobile: every legacy event's cards survive a draft round-trip", () => {
  for (const f of files) {
    const quest = JSON.parse(fs.readFileSync(path.join(eventsDir, f), "utf-8"));
    const bundle = mobile.buildBundle(mobile.draftFromParsed(deepClone(quest)));
    assert.deepStrictEqual(bundle.cards, blankProseToNull(quest.cards), f);
    assert.deepStrictEqual(bundle.at, quest.at, f);
  }
});

test("mobile: a fresh choice still saves as {label, effects: [], result_text}", () => {
  const draft = { id: "x", cards: [{ type: "choice", label: "", speaker: "", text: "", choices: [mobile.defaultChoice()] }], notesText: "" };
  assert.deepStrictEqual(mobile.buildBundle(draft).cards[0].choices, [{ label: null, effects: [], result_text: null }]);
});

const HUB_EVENT = {
  id: "hub_fixture",
  cards: [
    {
      type: "choice",
      label: null,
      speaker: null,
      text: "He waits.",
      choices: [
        { label: "Ask", effects: [], result_text: null, goto: 1 },
        { label: "Take the keys", effects: [], result_text: null, goto: 2 },
      ],
    },
    { type: "narration", label: null, speaker: null, text: "Answer.", goto: 0 },
    { type: "narration", label: null, speaker: null, text: "Keys." },
  ],
};

test("advanceRule / setAdvanceRule / setOptionExit read and write the hub fields", () => {
  const card = {};
  assert.deepStrictEqual(advanceRule(card), { kind: "anytime", n: 0 });
  setAdvanceRule(card, "all");
  assert.deepStrictEqual([card.advance, advanceRule(card).kind], ["all", "all"]);
  setAdvanceRule(card, "after", 3);
  assert.deepStrictEqual([card.advance, advanceRule(card).n], [3, 3]);
  setAdvanceRule(card, "after", 0);
  assert.strictEqual(card.advance, 1);
  setAdvanceRule(card, "anytime");
  assert.strictEqual("advance" in card, false);
  const opt = {};
  setOptionExit(opt, true);
  assert.strictEqual(opt.exit, true);
  setOptionExit(opt, false);
  assert.strictEqual("exit" in opt, false);
});

test("mobile: exit and advance round-trip through a draft", () => {
  const quest = deepClone(HUB_EVENT);
  quest.cards[0].advance = "all";
  quest.cards[0].choices[1].exit = true;
  const bundle = mobile.buildBundle(mobile.draftFromParsed(deepClone(quest)));
  assert.strictEqual(bundle.cards[0].advance, "all");
  assert.strictEqual(bundle.cards[0].choices[1].exit, true);
  assert.deepStrictEqual(bundle.cards, quest.cards);
});

console.log(passed + " test(s) passed");

// Promote a storyboard proposal (a .md file whose first ```json block is a branch draft) to a live flat event,
// and list / resolve its "for Claude" comments. Runs tools/storyboard.html's own draft model (the section between
// its "Draft model (pure)" markers), so the conversion is the exact code the tool's Promote button runs.
//
//   node tools/promote_storyboard.js comments <proposal.md>          open "for Claude" comments, one per line
//   node tools/promote_storyboard.js resolve <proposal.md> <id>...   mark those comments resolved (saved in place)
//   node tools/promote_storyboard.js promote <proposal.md> [--out <file>] [--stdout]
//       writes data/events/<id>.json (or --out); refuses while open "for Claude" comments remain.

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");

function loadModel() {
  const html = fs.readFileSync(path.join(__dirname, "storyboard.html"), "utf-8");
  const section = (a, b) => {
    const s = html.indexOf(a), e = html.indexOf(b);
    if (s === -1 || e === -1) throw new Error(`storyboard.html: can't find ${a}`);
    return html.slice(s, e);
  };
  return new Function(
    section("/* ---------- Choice mechanics (shared) ---------- */", "/* ---------- End choice mechanics ---------- */") +
      section("/* ---------- Draft model (pure) ---------- */", "/* ---------- End draft model ---------- */") +
      "\nreturn { parseProposal, spliceDraft, filterComments, updateComment, anchorText, promoteForWrite };"
  )();
}

function readBoard(m, file) {
  const md = fs.readFileSync(file, "utf-8");
  const board = m.parseProposal(path.basename(file), md);
  if (!board) throw new Error(`${file} has no \`\`\`json block`);
  if (board.error) throw new Error(`${file}: ${board.error}`);
  return { md, draft: board.draft, legacy: board.legacy };
}

function main(argv) {
  const [cmd, file, ...rest] = argv;
  if (!cmd || !file) throw new Error("usage: promote_storyboard.js comments|resolve|promote <proposal.md> ...");
  const m = loadModel();
  const { md, draft } = readBoard(m, file);
  const open = m.filterComments(draft, { kind: "claude", status: "open" });

  if (cmd === "comments") {
    if (!open.length) console.log("no open comments for Claude");
    for (const c of open) console.log(`${c.id}\t${m.anchorText(draft, c.anchor || {})}\t${c.text}`);
    return;
  }
  if (cmd === "resolve") {
    if (!rest.length) throw new Error("resolve: name at least one comment id");
    for (const id of rest) m.updateComment(draft, id, { status: "resolved" });
    fs.writeFileSync(file, m.spliceDraft(md, draft));
    console.log(`resolved ${rest.join(", ")} in ${file}`);
    return;
  }
  if (cmd === "promote") {
    const { event, dropped, text, file: name } = m.promoteForWrite(draft);
    if (dropped.length) console.error(`left out (no path reaches them): ${dropped.join(", ")}`);
    if (rest.includes("--stdout")) { process.stdout.write(text); return; }
    const oi = rest.indexOf("--out");
    const out = oi >= 0 ? rest[oi + 1] : path.join(ROOT, "data", "events", name);
    const existed = fs.existsSync(out);
    fs.writeFileSync(out, text);
    console.log(`${existed ? "overwrote" : "wrote"} ${path.relative(ROOT, out)} (${event.cards.length} cards)`);
    return;
  }
  throw new Error(`unknown command ${cmd}`);
}

if (require.main === module) {
  try { main(process.argv.slice(2)); } catch (e) { console.error(e.message); process.exitCode = 1; }
}

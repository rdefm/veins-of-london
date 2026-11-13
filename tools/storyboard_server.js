// Vein storyboard server: plain Node, no dependencies. Serves tools/ plus a small file API over the repo.
// Run: node tools/storyboard_server.js [--port N]   (default 4317; PORT 0 = random)
// API (all need the access token as ?t=<token> or header x-token):
//   GET  /api/read?path=<rel>             raw bytes, header x-version = sha256 of content
//   GET  /api/list?path=<rel dir>         JSON [{name, dir}]
//   POST /api/write?path=<rel>[&version=] body = raw bytes; 409 if version given and not the file's current one
//   POST /api/delete?path=<rel>[&version=]
// Reads cover the whole repo; writes/deletes only under WRITE_ROOTS.

const http = require("http");
const fs = require("fs");
const path = require("path");
const os = require("os");
const crypto = require("crypto");

const REPO = path.resolve(__dirname, "..");
const TOOLS = __dirname;
const DEFAULT_PORT = 4317;
const WRITE_DIRS = [".scratch/", "data/events/", "data/quests/", "assets/events/", "assets/reference-plates/", "data/board_prose/"];
const WRITE_FILES = ["data/board.json"];
const MIME = {
  ".html": "text/html; charset=utf-8", ".js": "text/javascript; charset=utf-8", ".json": "application/json; charset=utf-8",
  ".css": "text/css; charset=utf-8", ".png": "image/png", ".jpg": "image/jpeg", ".svg": "image/svg+xml", ".md": "text/plain; charset=utf-8",
};

// ---------- QR encoder (byte mode, ECC level L, versions 1-10) ----------
const QR_ECC_PER_BLOCK = [0, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18];
const QR_BLOCKS = [0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4];
const GF_EXP = new Array(512), GF_LOG = new Array(256);
(function () { let x = 1; for (let i = 0; i < 255; i++) { GF_EXP[i] = x; GF_LOG[x] = i; x <<= 1; if (x & 0x100) x ^= 0x11d; } for (let i = 255; i < 512; i++) GF_EXP[i] = GF_EXP[i - 255]; })();
function gfMul(a, b) { return a && b ? GF_EXP[GF_LOG[a] + GF_LOG[b]] : 0; }
function rsRemainder(data, degree) {
  let gen = [1];
  for (let i = 0; i < degree; i++) {
    const next = new Array(gen.length + 1).fill(0);
    for (let j = 0; j < gen.length; j++) { next[j] ^= gen[j]; next[j + 1] ^= gfMul(gen[j], GF_EXP[i]); }
    gen = next;
  }
  const rem = new Array(degree).fill(0);
  for (const b of data) {
    const f = b ^ rem.shift(); rem.push(0);
    for (let i = 0; i < degree; i++) rem[i] ^= gfMul(gen[i + 1], f);
  }
  return rem;
}
function qrSize(v) { return 17 + 4 * v; }
function qrRawModules(v) {
  let n = (16 * v + 128) * v + 64;
  if (v >= 2) { const a = Math.floor(v / 7) + 2; n -= (25 * a - 10) * a - 55; if (v >= 7) n -= 36; }
  return n;
}
function qrDataCodewords(v) { return Math.floor(qrRawModules(v) / 8) - QR_ECC_PER_BLOCK[v] * QR_BLOCKS[v]; }
function alignPositions(v) {
  if (v === 1) return [];
  const n = Math.floor(v / 7) + 2, size = qrSize(v);
  const step = v === 32 ? 26 : Math.ceil((v * 4 + 4) / (n * 2 - 2)) * 2;
  const r = [6];
  for (let p = size - 7; r.length < n; p -= step) r.splice(1, 0, p);
  return r;
}
function qrEncode(text) {
  const bytes = Buffer.from(text, "utf-8");
  let v = 1;
  while (v <= 10 && qrDataCodewords(v) < bytes.length + 2) v++;
  if (v > 10) throw new Error("QR text too long");
  const cap = qrDataCodewords(v);
  const bits = [];
  const put = (val, len) => { for (let i = len - 1; i >= 0; i--) bits.push((val >>> i) & 1); };
  put(4, 4); put(bytes.length, 8); for (const b of bytes) put(b, 8);
  put(0, Math.min(4, cap * 8 - bits.length));
  while (bits.length % 8) bits.push(0);
  for (let pad = 0xec; bits.length < cap * 8; pad ^= 0xec ^ 0x11) put(pad, 8);
  const data = []; for (let i = 0; i < bits.length; i += 8) data.push(parseInt(bits.slice(i, i + 8).join(""), 2));
  // split into blocks, add ECC, interleave
  const nb = QR_BLOCKS[v], ecc = QR_ECC_PER_BLOCK[v], raw = Math.floor(qrRawModules(v) / 8);
  const shortLen = Math.floor(raw / nb) - ecc, numShort = nb - raw % nb;
  const blocks = []; let k = 0;
  for (let i = 0; i < nb; i++) {
    const len = shortLen + (i < numShort ? 0 : 1);
    const d = data.slice(k, k + len); k += len;
    blocks.push({ d, e: rsRemainder(d, ecc) });
  }
  const out = [];
  for (let i = 0; i < shortLen + 1; i++) for (let j = 0; j < nb; j++) if (i < blocks[j].d.length) out.push(blocks[j].d[i]);
  for (let i = 0; i < ecc; i++) for (let j = 0; j < nb; j++) out.push(blocks[j].e[i]);
  const size = qrSize(v);
  const mk = () => Array.from({ length: size }, () => new Array(size).fill(false));
  const base = mk(), fn = mk();
  const setF = (x, y, dark) => { if (x >= 0 && y >= 0 && x < size && y < size) { base[y][x] = dark; fn[y][x] = true; } };
  for (let i = 0; i < size; i++) { setF(6, i, i % 2 === 0); setF(i, 6, i % 2 === 0); }
  const finder = (cx, cy) => { for (let dy = -4; dy <= 4; dy++) for (let dx = -4; dx <= 4; dx++) { const d = Math.max(Math.abs(dx), Math.abs(dy)); setF(cx + dx, cy + dy, d !== 2 && d !== 4); } };
  finder(3, 3); finder(size - 4, 3); finder(3, size - 4);
  const ap = alignPositions(v);
  for (let i = 0; i < ap.length; i++) for (let j = 0; j < ap.length; j++) {
    if ((i === 0 && j === 0) || (i === 0 && j === ap.length - 1) || (i === ap.length - 1 && j === 0)) continue;
    for (let dy = -2; dy <= 2; dy++) for (let dx = -2; dx <= 2; dx++) setF(ap[i] + dx, ap[j] + dy, Math.max(Math.abs(dx), Math.abs(dy)) !== 1);
  }
  const drawFormat = (m, target) => {
    const d = (1 << 3) | m; // ECC L = 01
    let rem = d; for (let i = 0; i < 10; i++) rem = (rem << 1) ^ ((rem >>> 9) * 0x537);
    const f = ((d << 10) | rem) ^ 0x5412, bit = (i) => ((f >>> i) & 1) !== 0;
    const set = (x, y, dark) => { target[y][x] = dark; };
    for (let i = 0; i <= 5; i++) set(8, i, bit(i));
    set(8, 7, bit(6)); set(8, 8, bit(7)); set(7, 8, bit(8));
    for (let i = 9; i < 15; i++) set(14 - i, 8, bit(i));
    for (let i = 0; i < 8; i++) set(size - 1 - i, 8, bit(i));
    for (let i = 8; i < 15; i++) set(8, size - 15 + i, bit(i));
    set(8, size - 8, true);
  };
  for (let i = 0; i < 9; i++) { fn[8][i] = fn[i][8] = true; }
  for (let i = 0; i < 8; i++) { fn[8][size - 1 - i] = true; fn[size - 1 - i][8] = true; }
  fn[size - 8][8] = true;
  if (v >= 7) {
    let rem = v; for (let i = 0; i < 12; i++) rem = (rem << 1) ^ ((rem >>> 11) * 0x1f25);
    const bitsV = (v << 12) | rem;
    for (let i = 0; i < 18; i++) {
      const dark = ((bitsV >>> i) & 1) !== 0, a = size - 11 + (i % 3), b = Math.floor(i / 3);
      setF(a, b, dark); setF(b, a, dark);
    }
  }
  // place data bits in zigzag
  const cw = out, total = cw.length * 8;
  const place = mk(); let bi = 0;
  for (let right = size - 1; right >= 1; right -= 2) {
    if (right === 6) right = 5;
    for (let vert = 0; vert < size; vert++) for (let j = 0; j < 2; j++) {
      const x = right - j, upward = ((right + 1) & 2) === 0, y = upward ? size - 1 - vert : vert;
      if (!fn[y][x] && bi < total) { place[y][x] = ((cw[bi >>> 3] >>> (7 - (bi & 7))) & 1) !== 0; bi++; }
    }
  }
  const MASKS = [(x, y) => (x + y) % 2 === 0, (x, y) => y % 2 === 0, (x, y) => x % 3 === 0, (x, y) => (x + y) % 3 === 0,
    (x, y) => (Math.floor(x / 3) + Math.floor(y / 2)) % 2 === 0, (x, y) => x * y % 2 + x * y % 3 === 0,
    (x, y) => (x * y % 2 + x * y % 3) % 2 === 0, (x, y) => ((x + y) % 2 + x * y % 3) % 2 === 0];
  const build = (m) => {
    const g = mk();
    for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) g[y][x] = fn[y][x] ? base[y][x] : place[y][x] !== MASKS[m](x, y);
    drawFormat(m, g);
    return g;
  };
  const penalty = (g) => {
    let p = 0;
    for (let pass = 0; pass < 2; pass++) for (let a = 0; a < size; a++) {
      let run = 1;
      for (let b = 1; b < size; b++) {
        const cur = pass ? g[b][a] : g[a][b], prev = pass ? g[b - 1][a] : g[a][b - 1];
        if (cur === prev) { run++; if (run === 5) p += 3; else if (run > 5) p++; } else run = 1;
      }
    }
    for (let y = 0; y < size - 1; y++) for (let x = 0; x < size - 1; x++) if (g[y][x] === g[y][x + 1] && g[y][x] === g[y + 1][x] && g[y][x] === g[y + 1][x + 1]) p += 3;
    let dark = 0; for (const row of g) for (const c of row) if (c) dark++;
    p += Math.floor(Math.abs(dark * 20 - size * size * 10) / (size * size)) * 10;
    return p;
  };
  let best = null, bestP = Infinity;
  for (let m = 0; m < 8; m++) { const g = build(m), p = penalty(g); if (p < bestP) { bestP = p; best = g; } }
  return best;
}
// Two module rows per terminal line using half-block glyphs; 2-module white quiet zone.
function qrToTerminal(grid) {
  const q = 2, n = grid.length, at = (x, y) => (x >= 0 && y >= 0 && x < n && y < n) ? grid[y][x] : false;
  const lines = [];
  for (let y = -q; y < n + q; y += 2) {
    let s = "";
    for (let x = -q; x < n + q; x++) {
      const t = at(x, y), b = at(x, y + 1);
      s += t && b ? " " : t ? "▄" : b ? "▀" : "█";
    }
    lines.push(s);
  }
  return lines.join("\n");
}

// ---------- file API ----------
function sha(buf) { return crypto.createHash("sha256").update(buf).digest("hex"); }
// Returns the absolute path for a repo-relative path, or null if it escapes the repo.
function resolveRepoPath(rel) {
  if (typeof rel !== "string" || rel.includes("\0")) return null;
  const abs = path.resolve(REPO, rel.replace(/^[\\/]+/, ""));
  const back = path.relative(REPO, abs);
  if (back.startsWith("..") || path.isAbsolute(back)) return null;
  return abs;
}
function isWritable(abs) {
  const rel = path.relative(REPO, abs).split(path.sep).join("/");
  return rel !== "" && (WRITE_FILES.includes(rel) || WRITE_DIRS.some((d) => rel.startsWith(d)));
}
function readBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = []; let n = 0;
    req.on("data", (c) => { n += c.length; if (n > 64 * 1024 * 1024) { reject(new Error("too large")); req.destroy(); } else chunks.push(c); });
    req.on("end", () => resolve(Buffer.concat(chunks)));
    req.on("error", reject);
  });
}
function send(res, code, body, headers) {
  res.writeHead(code, Object.assign({ "cache-control": "no-store" }, headers || {}));
  res.end(body);
}
function sendJSON(res, code, obj) { send(res, code, JSON.stringify(obj), { "content-type": MIME[".json"] }); }

function createServer(token) {
  return http.createServer(async (req, res) => {
    try {
      const url = new URL(req.url, "http://x");
      if (url.pathname.startsWith("/api/")) {
        const given = url.searchParams.get("t") || req.headers["x-token"];
        if (given !== token) return sendJSON(res, 401, { error: "token required" });
        const rel = url.searchParams.get("path") || "";
        const abs = resolveRepoPath(rel);
        if (!abs) return sendJSON(res, 400, { error: "path outside repo" });
        const op = url.pathname.slice(5);
        if (op === "read" && req.method === "GET") {
          if (!fs.existsSync(abs) || !fs.statSync(abs).isFile()) return sendJSON(res, 404, { error: "not found" });
          const buf = fs.readFileSync(abs);
          return send(res, 200, buf, { "content-type": MIME[path.extname(abs).toLowerCase()] || "application/octet-stream", "x-version": sha(buf) });
        }
        if (op === "list" && req.method === "GET") {
          if (!fs.existsSync(abs) || !fs.statSync(abs).isDirectory()) return sendJSON(res, 404, { error: "not found" });
          return sendJSON(res, 200, fs.readdirSync(abs, { withFileTypes: true }).map((d) => ({ name: d.name, dir: d.isDirectory() })));
        }
        if ((op === "write" || op === "delete") && req.method === "POST") {
          if (!isWritable(abs)) return sendJSON(res, 403, { error: "path not writable" });
          const expected = url.searchParams.get("version");
          const exists = fs.existsSync(abs);
          if (exists && fs.statSync(abs).isDirectory()) return sendJSON(res, 400, { error: "is a directory" });
          if (expected !== null && exists && sha(fs.readFileSync(abs)) !== expected) return sendJSON(res, 409, { error: "version conflict" });
          if (op === "delete") {
            if (!exists) return sendJSON(res, 404, { error: "not found" });
            fs.unlinkSync(abs);
            return sendJSON(res, 200, { ok: true });
          }
          const body = await readBody(req);
          fs.mkdirSync(path.dirname(abs), { recursive: true });
          fs.writeFileSync(abs, body);
          return sendJSON(res, 200, { ok: true, version: sha(body) });
        }
        return sendJSON(res, 404, { error: "unknown api call" });
      }
      // static: tools/ folder
      let rel = decodeURIComponent(url.pathname);
      if (rel === "/") rel = "/storyboard.html";
      const abs = path.resolve(TOOLS, "." + rel);
      const back = path.relative(TOOLS, abs);
      if (back.startsWith("..") || path.isAbsolute(back) || !fs.existsSync(abs) || !fs.statSync(abs).isFile()) return send(res, 404, "not found", { "content-type": "text/plain" });
      return send(res, 200, fs.readFileSync(abs), { "content-type": MIME[path.extname(abs).toLowerCase()] || "application/octet-stream" });
    } catch (err) {
      sendJSON(res, 500, { error: String(err && err.message || err) });
    }
  });
}

function lanAddress() {
  for (const list of Object.values(os.networkInterfaces())) for (const i of list || []) if (i.family === "IPv4" && !i.internal) return i.address;
  return null;
}

function start(port) {
  const token = crypto.randomBytes(8).toString("hex");
  const server = createServer(token);
  return new Promise((resolve) => server.listen(port, "0.0.0.0", () => resolve({ server, token, port: server.address().port })));
}

module.exports = { rsRemainder, start, createServer, qrEncode, qrToTerminal, resolveRepoPath, isWritable, REPO };

if (require.main === module) {
  const i = process.argv.indexOf("--port");
  const want = i !== -1 ? parseInt(process.argv[i + 1], 10) : DEFAULT_PORT;
  start(want).then(({ token, port }) => {
    const lan = lanAddress();
    const laptop = `http://localhost:${port}/?t=${token}`;
    const phone = lan ? `http://${lan}:${port}/?t=${token}` : null;
    console.log("Vein storyboard server");
    console.log(`Laptop  ${laptop}`);
    if (phone) { console.log(`Phone   ${phone}\n`); console.log(qrToTerminal(qrEncode(phone))); }
    else console.log("Phone   (no LAN address found)");
    console.log("\nCtrl+C to stop.");
  });
}

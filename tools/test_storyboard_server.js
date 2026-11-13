// Node test for tools/storyboard_server.js. Run with: node tools/test_storyboard_server.js
// Starts the server on a random port and drives it over HTTP.

const assert = require("assert");
const fs = require("fs");
const path = require("path");
const http = require("http");
const srv = require("./storyboard_server.js");

function call(port, method, url, body, headers) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: "127.0.0.1", port, method, path: url, headers: headers || {} }, (res) => {
      const chunks = []; res.on("data", (c) => chunks.push(c));
      res.on("end", () => resolve({ status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks) }));
    });
    req.on("error", reject);
    if (body !== undefined) req.write(body);
    req.end();
  });
}

(async () => {
  const { server, token, port } = await srv.start(0);
  const t = `t=${token}`;
  const tmpRel = ".scratch/_server_test_tmp/note.txt";
  const tmpAbs = path.join(srv.REPO, tmpRel);
  const cleanup = () => fs.rmSync(path.join(srv.REPO, ".scratch/_server_test_tmp"), { recursive: true, force: true });
  cleanup();
  try {
    // page served (no token needed for the static page)
    let r = await call(port, "GET", "/");
    assert.strictEqual(r.status, 200); assert(r.body.toString().includes("<html"));

    // token required
    r = await call(port, "GET", "/api/read?path=CLAUDE.md");
    assert.strictEqual(r.status, 401);
    r = await call(port, "GET", "/api/read?path=CLAUDE.md&t=wrong");
    assert.strictEqual(r.status, 401);
    r = await call(port, "GET", "/api/read?path=CLAUDE.md", undefined, { "x-token": token });
    assert.strictEqual(r.status, 200);

    // read anywhere in repo + version
    r = await call(port, "GET", `/api/read?path=CLAUDE.md&${t}`);
    assert.strictEqual(r.status, 200);
    assert.strictEqual(r.body.toString(), fs.readFileSync(path.join(srv.REPO, "CLAUDE.md"), "utf-8"));
    assert(/^[0-9a-f]{64}$/.test(r.headers["x-version"]));
    r = await call(port, "GET", `/api/read?path=nope/missing.txt&${t}`);
    assert.strictEqual(r.status, 404);

    // list
    r = await call(port, "GET", `/api/list?path=tools&${t}`);
    assert.strictEqual(r.status, 200);
    assert(JSON.parse(r.body).some((e) => e.name === "storyboard.html" && !e.dir));

    // traversal refused
    r = await call(port, "GET", `/api/read?path=${encodeURIComponent("../secret.txt")}&${t}`);
    assert.strictEqual(r.status, 400);
    r = await call(port, "POST", `/api/write?path=${encodeURIComponent(".scratch/../../x.txt")}&${t}`, "x");
    assert.strictEqual(r.status, 400);
    r = await call(port, "GET", "/..%2fCLAUDE.md");
    assert.strictEqual(r.status, 404);

    // write outside whitelist refused
    for (const p of ["CLAUDE.md", "data/other.json", "systems/x.gd", "data/events"]) {
      r = await call(port, "POST", `/api/write?path=${encodeURIComponent(p)}&${t}`, "x");
      assert.strictEqual(r.status, 403, p);
    }
    r = await call(port, "POST", `/api/delete?path=CLAUDE.md&${t}`);
    assert.strictEqual(r.status, 403);

    // create new file, then version rules
    r = await call(port, "POST", `/api/write?path=${encodeURIComponent(tmpRel)}&${t}`, "one");
    assert.strictEqual(r.status, 200);
    const v1 = JSON.parse(r.body).version;
    r = await call(port, "GET", `/api/read?path=${encodeURIComponent(tmpRel)}&${t}`);
    assert.strictEqual(r.headers["x-version"], v1);
    r = await call(port, "POST", `/api/write?path=${encodeURIComponent(tmpRel)}&version=${"0".repeat(64)}&${t}`, "stale");
    assert.strictEqual(r.status, 409);
    assert.strictEqual(fs.readFileSync(tmpAbs, "utf-8"), "one");
    r = await call(port, "POST", `/api/write?path=${encodeURIComponent(tmpRel)}&version=${v1}&${t}`, "two");
    assert.strictEqual(r.status, 200);
    assert.strictEqual(fs.readFileSync(tmpAbs, "utf-8"), "two");

    // stale delete refused, current delete ok
    r = await call(port, "POST", `/api/delete?path=${encodeURIComponent(tmpRel)}&version=${v1}&${t}`);
    assert.strictEqual(r.status, 409);
    r = await call(port, "POST", `/api/delete?path=${encodeURIComponent(tmpRel)}&${t}`);
    assert.strictEqual(r.status, 200);
    assert(!fs.existsSync(tmpAbs));

    // whitelisted single file path allowed
    assert(srv.isWritable(path.join(srv.REPO, "data/board.json")));
    assert(srv.isWritable(path.join(srv.REPO, "data/board_prose/a.json")));
    assert(!srv.isWritable(path.join(srv.REPO, "data/board.json.bak.x/../../CLAUDE.md")));

    // QR: known Reed-Solomon vector (version 1-M data, 10 ECC) is exercised via a full encode round-trip below.
    const g = srv.qrEncode("http://192.168.100.200:4317/?t=0123456789abcdef");
    assert.strictEqual(g.length, g[0].length);
    assert([29, 33, 37, 41].includes(g.length), "unexpected QR size " + g.length);
    // finder pattern top-left: 7x7 ring
    for (let i = 0; i < 7; i++) { assert(g[0][i] && g[6][i] && g[i][0] && g[i][6]); }
    assert(g[3][3] && !g[1][1]);
    // format info (ECC L) bits are a valid BCH codeword: recompute from the top-left copy
    let f = 0; const pos = [[8,0],[8,1],[8,2],[8,3],[8,4],[8,5],[8,7],[8,8],[7,8],[5,8],[4,8],[3,8],[2,8],[1,8],[0,8]];
    pos.forEach(([x, y], i) => { if (g[y][x]) f |= 1 << i; });
    f ^= 0x5412;
    let rem = f >>> 10; for (let i = 0; i < 10; i++) rem = (rem << 1) ^ ((rem >>> 9) * 0x537);
    assert.strictEqual((f >>> 10) >>> 3, 1, "ECC level bits not L");
    assert.strictEqual(((f >>> 10) << 10 | (rem & 0x3ff)), f, "format BCH mismatch");
    const term = srv.qrToTerminal(g);
    assert(term.split("\n").length === Math.ceil((g.length + 4) / 2));

    console.log("storyboard server tests passed");
  } finally {
    cleanup();
    server.close();
  }
})().catch((e) => { console.error(e); process.exit(1); });

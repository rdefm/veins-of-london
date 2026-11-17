"""Vision backends for the art judge.

One call: instruction text + ordered labelled images + JSON schema in,
parsed JSON out (or BackendError). `ClaudeBackend` shells out to the Claude
CLI in headless print mode (Read tool only); `FakeBackend` replays recorded
replies so the judge runs offline in tests.
"""
import json
import os
import re
import subprocess


class BackendError(Exception):
    pass


def parse_json_text(text):
    """Parse a model reply that should be a JSON object (tolerates code fences)."""
    s = (text or "").strip()
    m = re.match(r"^```(?:json)?\s*(.*?)\s*```$", s, re.S)
    if m:
        s = m.group(1)
    try:
        obj = json.loads(s)
    except ValueError:
        a, b = s.find("{"), s.rfind("}")
        if a < 0 or b <= a:
            raise BackendError("reply is not JSON")
        try:
            obj = json.loads(s[a:b + 1])
        except ValueError as e:
            raise BackendError("reply is not JSON: %s" % e)
    if not isinstance(obj, dict):
        raise BackendError("reply JSON is not an object")
    return obj


def build_prompt(instruction, images, schema):
    lines = ["You are reviewing pixel-art images. Use the Read tool to open each image file listed below, "
             "in order, before answering.", "", "Images:"]
    for i, (label, path) in enumerate(images, 1):
        lines.append("%d. [%s] %s" % (i, label, path))
    lines += ["", instruction, "",
              "Reply with ONLY a JSON object matching this JSON schema (no prose, no code fences):",
              json.dumps(schema)]
    return "\n".join(lines)


class ClaudeBackend:
    name = "claude"

    def __init__(self, cwd, model=None, timeout=600, exe="claude"):
        self.cwd, self.model, self.timeout, self.exe = cwd, model, timeout, exe
        self.model_used = model or "claude-cli-default"

    def call(self, key, instruction, images, schema):
        cmd = [self.exe, "-p", "--output-format", "json", "--tools", "Read",
               "--allowedTools", "Read", "--no-session-persistence", "--disable-slash-commands",
               "--json-schema", json.dumps(schema)]
        if self.model:
            cmd += ["--model", self.model]
        prompt = build_prompt(instruction, images, schema)
        try:
            p = subprocess.run(cmd, input=prompt, capture_output=True, text=True, encoding="utf-8",
                               cwd=self.cwd, timeout=self.timeout)
        except (OSError, subprocess.TimeoutExpired) as e:
            raise BackendError("claude cli failed: %s" % e)
        if p.returncode != 0:
            raise BackendError("claude cli exit %d: %s" % (p.returncode, (p.stderr or p.stdout)[:300]))
        try:
            env = json.loads(p.stdout)
        except ValueError:
            raise BackendError("claude cli output is not JSON")
        if not isinstance(env, dict):
            raise BackendError("claude cli output is not an object")
        if env.get("is_error"):
            raise BackendError("claude cli error: %s" % str(env.get("result"))[:300])
        if isinstance(env.get("structured_output"), dict):
            return env["structured_output"]
        return parse_json_text(env.get("result"))


class FakeBackend:
    """Replays replies. `queue` (list of dicts / BackendError / str) is consumed in order;
    otherwise `<replies_dir>/<key>.json` is read. A str reply is returned as raw model text."""
    name = "fake"
    model_used = "fake"

    def __init__(self, replies_dir=None, queue=None):
        self.replies_dir = replies_dir
        self.queue = list(queue) if queue is not None else None
        self.calls = []

    def call(self, key, instruction, images, schema):
        self.calls.append({"key": key, "instruction": instruction, "images": list(images)})
        if self.queue is not None:
            if not self.queue:
                raise BackendError("fake backend: no replies left")
            r = self.queue.pop(0)
        else:
            path = os.path.join(self.replies_dir or "", key + ".json")
            if not os.path.isfile(path):
                raise BackendError("fake backend: no recording for %s" % key)
            with open(path, encoding="utf-8") as f:
                r = json.load(f)
        if isinstance(r, BackendError):
            raise r
        if isinstance(r, str):
            return parse_json_text(r)
        return r


class RecordingBackend:
    """Wraps a backend and saves each successful reply as `<dir>/<key>.json`."""

    def __init__(self, inner, out_dir):
        self.inner, self.out_dir = inner, out_dir
        self.name = inner.name
        self.model_used = inner.model_used

    def call(self, key, instruction, images, schema):
        r = self.inner.call(key, instruction, images, schema)
        os.makedirs(self.out_dir, exist_ok=True)
        with open(os.path.join(self.out_dir, key + ".json"), "w", encoding="utf-8") as f:
            json.dump(r, f, indent=2)
        return r

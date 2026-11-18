import copy
import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
TOOLS = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, os.path.join(TOOLS, "art_judge"))
sys.path.insert(0, os.path.join(TOOLS, "art_judge", "tests"))

import gen  # noqa: E402
import spend  # noqa: E402
import judge  # noqa: E402
from image_backend import FakeImageBackend  # noqa: E402
from test_batch import ScoringBackend  # noqa: E402
from test_judge import BOARD, CANVAS, IDS, CHECKLIST_REPLY, good_reply, png  # noqa: E402

PLATES = "assets/reference-plates"
FAKE_KEY = "sk-test-FAKEKEY-1234567890"


def rule(rid, kind, name, status="accepted", text=None):
    return {"id": rid, "scope": {"kind": kind, "name": name}, "text": text or "Rule %s text." % rid, "status": status}


class RuleScoringBackend(ScoringBackend):
    """Passes every checklist item, including the in-scope rule items."""
    def call(self, key, instruction, images, schema):
        if key.startswith("checklist"):
            return super().call(key, instruction, images, schema)
        self.calls.append({"key": key})
        return good_reply(IDS + ["rule-g1", "rule-c1", "rule-p1"])


class GenBase(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.ws = gen.GenWorkspace(self.tmp)
        self.board = copy.deepcopy(BOARD)
        shot = self.board["shots"][0]
        shot.update({"saveAs": "assets/reference-plates/ev_S1_archie.png", "plate": "P1",
                     "attach": ["assets/character-references/Archie/Archie_biz_sprite_master.png",
                                "assets/reference-plates/ev_blank_plate.png",
                                "assets/reference-plates/ev_S0_earlier.png"],
                     "prompt": "Attach: stale.png.\nUsing the room, add Archie leaning on the wall.\n" + gen.FIXED_TAIL,
                     "cast": ["Archie"]})
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), self.board)
        png(os.path.join(self.tmp, "assets/character-references/Archie/Archie_biz_sprite_master.png"))
        png(os.path.join(self.tmp, PLATES, "ev_blank_plate.png"))
        png(os.path.join(self.tmp, PLATES, "ev_S0_earlier.png"))
        self.ws.write_json(os.path.join(self.ws.judge_dir(), "rules.json"), [
            rule("g1", "global", "", text="Global accepted."),
            rule("c1", "character", "Archie", text="Archie accepted."),
            rule("p1", "plate", "P1", text="Plate P1 accepted."),
            rule("x1", "character", "Nadia", text="Nadia out of scope."),
            rule("x2", "plate", "P9", text="Other plate out of scope."),
            rule("n1", "global", "", status="proposed", text="Proposed only."),
            rule("n2", "global", "", status="rejected", text="Rejected only."),
        ])

    def run_gen(self, takes=4, jb=None):
        ib = FakeImageBackend(size=tuple(CANVAS))
        jb = jb or RuleScoringBackend()
        log, path = gen.run_gen(self.ws, ib, jb, "ev", "S1", takes, size=tuple(CANVAS))
        return ib, jb, log, path

    def all_files(self):
        out = set()
        for root, _, names in os.walk(self.tmp):
            for n in names:
                out.add(os.path.relpath(os.path.join(root, n), self.tmp).replace(os.sep, "/"))
        return out


class Takes(GenBase):
    def test_n_takes_written_and_judged(self):
        _, jb, log, _ = self.run_gen(3)
        files = sorted(os.listdir(os.path.join(self.tmp, PLATES)))
        self.assertEqual([f for f in files if "_archie" in f], ["ev_S1_archie_v1.png", "ev_S1_archie_v2.png",
                                                                 "ev_S1_archie_v3.png"])
        for n in (1, 2, 3):
            j = judge.read_json(os.path.join(self.ws.event_dir("ev"), "judgements", "ev_S1_archie_v%d.judgement.json" % n))
            self.assertEqual(j["verdict"], "pass")
            self.assertIsNotNone(j["rank"])
        self.assertEqual(len(log["takes"]), 3)

    def test_default_is_four_takes(self):
        self.assertEqual(gen.DEFAULT_TAKES, 4)
        _, _, log, _ = self.run_gen(gen.DEFAULT_TAKES)
        self.assertEqual(len(log["takes"]), 4)

    def test_next_free_version_skips_existing(self):
        png(os.path.join(self.tmp, PLATES, "ev_S1_archie.png"), tuple(CANVAS))
        png(os.path.join(self.tmp, PLATES, "ev_S1_archie_v3.png"), tuple(CANVAS))
        self.run_gen(2)
        names = sorted(n for n in os.listdir(os.path.join(self.tmp, PLATES)) if "_archie" in n)
        self.assertEqual(names, ["ev_S1_archie.png", "ev_S1_archie_v3.png", "ev_S1_archie_v4.png",
                                 "ev_S1_archie_v5.png"])

    def test_shots_tab_discovery_sees_takes(self):
        self.run_gen(2)
        shot = judge.find_shot(judge.load_board(self.ws, "ev"), "S1")
        self.assertEqual([os.path.basename(p) for p in judge.find_drafts(self.ws, shot)],
                         ["ev_S1_archie_v1.png", "ev_S1_archie_v2.png"])


class RunLog(GenBase):
    def test_log_records_each_take(self):
        _, _, _, path = self.run_gen(2)
        log = judge.read_json(path)
        self.assertEqual(len(log["takes"]), 2)
        for t in log["takes"]:
            for k in ("prompt", "backend", "settings", "seed", "parent", "cost", "judgement"):
                self.assertIn(k, t)
            self.assertIsNone(t["parent"])
            self.assertEqual(t["backend"], "fake")
            self.assertGreater(t["cost"]["amount"], 0)
            self.assertTrue(os.path.isfile(os.path.join(self.tmp, t["judgement"])))
        self.assertTrue(os.path.abspath(path).startswith(self.ws.event_dir("ev")))
        self.assertAlmostEqual(log["totalCost"], 0.08)


class Prompt(GenBase):
    def test_attachments_first_rules_scoped_fixed_tail(self):
        ib, _, _, _ = self.run_gen(1)
        prompt = ib.calls[0]["prompt"]
        lines = prompt.split("\n")
        self.assertTrue(lines[0].startswith("Attach: "))
        self.assertIn("ev_blank_plate.png (plate)", lines[0])
        self.assertIn("Archie_biz_sprite_master.png (cast)", lines[0])
        self.assertIn("ev_S0_earlier.png (continuity)", lines[0])
        self.assertLess(lines[0].index("(plate)"), lines[0].index("(cast)"))
        self.assertNotIn("stale.png", prompt)
        for ok in ("Global accepted.", "Archie accepted.", "Plate P1 accepted."):
            self.assertIn(ok, prompt)
        for bad in ("Nadia out of scope", "Other plate out of scope", "Proposed only", "Rejected only"):
            self.assertNotIn(bad, prompt)
        self.assertTrue(prompt.endswith(gen.FIXED_TAIL))
        self.assertEqual(prompt.count(gen.FIXED_TAIL), 1)
        self.assertIn("Using the room, add Archie leaning on the wall.", prompt)

    def test_prompt_recorded_matches_sent(self):
        ib, _, log, _ = self.run_gen(1)
        self.assertEqual(log["takes"][0]["prompt"], ib.calls[0]["prompt"])

    def test_attachment_roles_passed_to_backend(self):
        ib, _, _, _ = self.run_gen(1)
        self.assertEqual([r for r, _ in ib.calls[0]["references"]], ["plate", "cast", "continuity"])


class Safety(GenBase):
    def test_nothing_written_outside_art_workspace_and_plates(self):
        os.makedirs(os.path.join(self.tmp, "data/events"))
        os.makedirs(os.path.join(self.tmp, "assets/events/ev"))
        ev_json = os.path.join(self.tmp, "data/events/ev.json")
        card = os.path.join(self.tmp, "assets/events/ev/ev_card1.png")
        with open(ev_json, "w") as f:
            f.write("{}")
        png(card)
        before = self.all_files()
        with open(ev_json, "rb") as f:
            ev_bytes = f.read()
        with open(card, "rb") as f:
            card_bytes = f.read()
        self.run_gen(2)
        new = self.all_files() - before
        self.assertTrue(new)
        for p in new:
            self.assertTrue(p.startswith(".scratch/event-art/") or
                            (p.startswith(PLATES + "/") and p.count("/") == 2), p)
        with open(ev_json, "rb") as f:
            self.assertEqual(f.read(), ev_bytes)
        with open(card, "rb") as f:
            self.assertEqual(f.read(), card_bytes)

    def test_write_take_refuses_other_folders(self):
        for bad in ("assets/events/ev/x.png", "data/events/x.png", PLATES + "/sub/x.png", "../x.png"):
            with self.assertRaises(gen.GenError):
                self.ws.write_take(os.path.join(self.tmp, bad), b"x")

    def test_secrets_never_written(self):
        old = {k: os.environ.get(k) for k in ("OPENAI_API_KEY", "GEMINI_API_KEY", "ANTHROPIC_API_KEY")}
        for k in old:
            os.environ[k] = FAKE_KEY
        try:
            self.run_gen(2)
        finally:
            for k, v in old.items():
                if v is None:
                    os.environ.pop(k, None)
                else:
                    os.environ[k] = v
        needle = FAKE_KEY.encode()
        for rel_path in self.all_files():
            with open(os.path.join(self.tmp, rel_path), "rb") as f:
                self.assertNotIn(needle, f.read(), rel_path)


class Cli(GenBase):
    def test_cli_missing_save_as(self):
        del self.board["shots"][0]["saveAs"]
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), self.board)
        with self.assertRaises(gen.GenError):
            self.run_gen(1)


class Spend(GenBase):
    def set_caps(self, per_run, per_month):
        self.ws.write_json(os.path.join(self.ws.judge_dir(), "autogen.json"),
                           {"caps": {"perRun": per_run, "perMonth": per_month}})

    def gen_at(self, takes, now, cost=0.04):
        ib = FakeImageBackend(cost_per_image=cost, size=tuple(CANVAS))
        return ib, gen.run_gen(self.ws, ib, RuleScoringBackend(), "ev", "S1", takes, size=tuple(CANVAS), now=now)

    def test_exactly_at_run_cap_allowed_one_over_refused(self):
        self.set_caps(0.08, 100)
        ib, (log, _) = self.gen_at(3, "2026-11-10T10:00:00Z")
        self.assertEqual(len(ib.calls), 2)
        self.assertEqual(log["runTotal"], 0.08)
        self.assertEqual(log["stopped"]["reason"], "cap")
        self.assertIn("per-run", log["stopped"]["detail"])

    def test_month_cap_holds_across_runs_and_resets(self):
        self.set_caps(100, 0.08)
        ib, (log, _) = self.gen_at(2, "2026-11-10T10:00:00Z")
        self.assertEqual(len(ib.calls), 2)
        ib, (log, _) = self.gen_at(1, "2026-11-20T10:00:00Z")
        self.assertEqual(len(ib.calls), 0)
        self.assertIn("per-month", log["stopped"]["detail"])
        self.assertEqual(log["monthToDate"], 0.08)
        ib, (log, _) = self.gen_at(1, "2026-12-01T00:00:00Z")
        self.assertEqual(len(ib.calls), 1)
        self.assertEqual(log["monthToDate"], 0.04)

    def test_cap_stop_keeps_earlier_work(self):
        self.set_caps(0.08, 100)
        _, (log, path) = self.gen_at(4, "2026-11-10T10:00:00Z")
        self.assertEqual(len(log["takes"]), 2)
        saved = judge.read_json(path)
        self.assertEqual(len(saved["takes"]), 2)
        self.assertEqual(saved["stopped"]["reason"], "cap")
        for t in saved["takes"]:
            self.assertTrue(os.path.isfile(os.path.join(self.tmp, t["file"])))
            self.assertTrue(os.path.isfile(os.path.join(self.tmp, t["judgement"])))
        self.assertEqual(len(spend_ledger(self.ws)["entries"]), 2)

    def test_ledger_records_every_call(self):
        self.set_caps(100, 100)
        self.gen_at(3, "2026-11-10T10:00:00Z")
        entries = spend_ledger(self.ws)["entries"]
        self.assertEqual([e["amount"] for e in entries], [0.04] * 3)
        self.assertEqual(entries[0]["eventId"], "ev")

    def test_estimate_confirm(self):
        asked = []
        ok = spend.make_confirm(True)
        self.assertTrue(ok(0.16, 4))
        import builtins
        real = builtins.input
        builtins.input = lambda prompt="": asked.append(prompt) or "n"
        self.addCleanup(setattr, builtins, "input", real)
        self.assertFalse(spend.make_confirm(False)(0.16, 4))
        self.assertIn("0.16", asked[0])

    def test_cli_declined_makes_no_calls(self):
        import builtins
        real = builtins.input
        builtins.input = lambda prompt="": "n"
        self.addCleanup(setattr, builtins, "input", real)
        rc = gen.main(["--board", "ev", "--shot", "S1", "--repo", self.tmp, "--backend", "fake"])
        self.assertEqual(rc, 1)
        self.assertFalse(os.path.exists(spend.ledger_path(self.ws)))

    def test_cli_yes_prints_totals(self):
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            rc = gen.main(["--board", "ev", "--shot", "S1", "--takes", "1", "--yes", "--repo", self.tmp,
                           "--backend", "fake", "--fake-replies", self.tmp])
        out = buf.getvalue()
        self.assertIn("run total", out)
        self.assertIn("month to date", out)


def spend_ledger(ws):
    return spend.load_ledger(ws)


if __name__ == "__main__":
    unittest.main()

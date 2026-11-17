import copy
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, HERE)

import judge  # noqa: E402
from backend import FakeBackend  # noqa: E402
from test_judge import BOARD, CANVAS, CHECKLIST_REPLY, IDS, good_reply, png  # noqa: E402

PLATES = "assets/reference-plates"


class ScoringBackend(FakeBackend):
    """Checklist reply for checklist keys; otherwise a good reply scored per draft stem (default 3.5)."""
    def __init__(self, scores=None, overrides=None):
        super().__init__(queue=[])
        self.scores, self.overrides = scores or {}, overrides or {}

    def call(self, key, instruction, images, schema):
        self.calls.append({"key": key})
        if key.startswith("checklist"):
            return CHECKLIST_REPLY
        stem = key.split("__")[-1]
        s = self.scores.get(stem, 3.5)
        return good_reply(IDS, self.overrides.get(stem), {"brief": s, "style": s, "cast": {"Archie": s}})

    def judged(self):
        return sorted(c["key"].split("__")[-1] for c in self.calls if c["key"].startswith("judge"))


class Batch(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.ws = judge.Workspace(self.tmp)
        self.board = copy.deepcopy(BOARD)
        self.board["shots"][0]["saveAs"] = "assets/reference-plates/ev_S1.png"
        self.board["shots"].append({"id": "S2", "title": "none", "cards": "main: c1", "saveAs": "ev_S2.png"})
        self.write_board()
        png(os.path.join(self.tmp, "assets/character-references/Archie/Archie_biz_sprite_master.png"))
        for n in ("ev_S1.png", "ev_S1_v2.png", "ev_S1_v2_clean.png", "ev_S1_v10.png", "ev_S11.png", "other_S1.png"):
            png(os.path.join(self.tmp, PLATES, n), tuple(CANVAS))
        with open(os.path.join(self.tmp, PLATES, "ev_S1_v3.txt"), "w") as f:
            f.write("not an image")

    def write_board(self):
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), self.board)

    def run_batch(self, be=None, shots=None, **kw):
        be = be or ScoringBackend()
        return be, judge.judge_batch(self.ws, be, "ev", shots, **kw)

    def jpath(self, stem):
        return os.path.join(self.ws.event_dir("ev"), "judgements", stem + ".judgement.json")

    def test_discovery_of_v_and_clean_files(self):
        names = [os.path.basename(p) for p in judge.find_drafts(self.ws, self.board["shots"][0])]
        self.assertEqual(names, ["ev_S1.png", "ev_S1_v2.png", "ev_S1_v2_clean.png", "ev_S1_v10.png"])

    def test_shot_and_board_scope(self):
        be, _ = self.run_batch(shots=["S1"])
        self.assertEqual(len(be.judged()), 4)
        shutil.rmtree(os.path.join(self.tmp, ".scratch/event-art/ev/judgements"))
        be, _ = self.run_batch()
        self.assertEqual(len(be.judged()), 4)  # S2 has no drafts

    def test_second_run_makes_no_calls(self):
        self.run_batch()
        be, (results, _, calls) = self.run_batch()
        self.assertEqual(be.calls, [])
        self.assertEqual((results, calls), ([], 0))

    def stem_judged(self, be):
        return be.judged()

    def test_draft_change_rejudges_only_that_draft(self):
        self.run_batch()
        png(os.path.join(self.tmp, PLATES, "ev_S1_v2.png"), tuple(CANVAS), (1, 2, 3))
        be, _ = self.run_batch()
        self.assertEqual(be.judged(), ["ev_S1_v2"])

    def test_brief_change_rejudges_shot(self):
        self.run_batch()
        self.board["shots"][0]["job"] = "Archie leaves."
        self.write_board()
        be, _ = self.run_batch()
        self.assertEqual(len(be.judged()), 4)
        self.assertEqual(len([c for c in be.calls if c["key"].startswith("checklist")]), 1)

    def test_style_change_rejudges_all(self):
        self.run_batch()
        self.ws.write_json(os.path.join(self.ws.judge_dir(), "style.json"), {"images": [], "card": "chunky"})
        be, _ = self.run_batch()
        self.assertEqual(len(be.judged()), 4)

    def test_unjudged_is_retried(self):
        be = ScoringBackend()
        be.call = lambda *a, **k: (_ for _ in ()).throw(judge.BackendError("boom"))
        _, (results, _, _) = self.run_batch(be)
        self.assertTrue(all(r["verdict"] == "unjudged" for r in results))
        be, _ = self.run_batch()
        self.assertEqual(len(be.judged()), 4)

    def test_call_count_and_confirm(self):
        seen = []
        with self.assertRaises(judge.JudgeError):
            self.run_batch(confirm=lambda n: seen.append(n) or False)
        self.assertEqual(seen, [5])  # checklist + 4 drafts
        self.assertFalse(os.path.exists(self.jpath("ev_S1")))
        be, _ = self.run_batch(confirm=lambda n: True)
        self.assertEqual(len(be.calls), 5)

    def test_rank_order_ties_and_unjudged(self):
        be = ScoringBackend(
            scores={"ev_S1": 3.2, "ev_S1_v2": 3.8, "ev_S1_v2_clean": 3.8, "ev_S1_v10": 3.9},
            overrides={"ev_S1_v10": {"h-text": "fail"}})
        _, (_, ranks, _) = self.run_batch(be)
        order = [os.path.basename(d) for d, _ in ranks["S1"]]
        # pass before fail; higher weakest score first; tie -> file name; v10 fails so last
        self.assertEqual(order, ["ev_S1_v2.png", "ev_S1_v2_clean.png", "ev_S1.png", "ev_S1_v10.png"])
        self.assertEqual(judge.read_json(self.jpath("ev_S1_v2"))["rank"], 1)
        self.assertEqual(judge.read_json(self.jpath("ev_S1_v10"))["rank"], 4)
        # an unjudged take ranks after the failing one
        j = judge.read_json(self.jpath("ev_S1_v2"))
        j.update(verdict="unjudged", error="x", scores={})
        self.ws.write_json(self.jpath("ev_S1_v2"), j)
        drafts = judge.find_drafts(self.ws, self.board["shots"][0])
        order = [os.path.basename(d) for d, _ in judge.rank_shot(self.ws, "ev", drafts)]
        self.assertEqual(order, ["ev_S1_v2_clean.png", "ev_S1.png", "ev_S1_v10.png", "ev_S1_v2.png"])


if __name__ == "__main__":
    unittest.main()

import json
import os
import shutil
import sys
import tempfile
import unittest

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import judge  # noqa: E402
import rules_propose as rp  # noqa: E402
from backend import BackendError, FakeBackend  # noqa: E402

DRAFT = "assets/reference-plates/ev_S1.png"


class Propose(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, self.tmp, True)
        self.ws = judge.Workspace(self.tmp)
        self.board = {"eventId": "ev", "shots": [{"id": "S1", "saveAs": "ev_S1.png", "plate": "yard", "cast": ["Archie"]}]}
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "board.json"), self.board)

    def notes(self, *entries):
        self.ws.write_json(os.path.join(self.ws.event_dir("ev"), "feedback.json"), list(entries))

    def fb(self, at, note, target=DRAFT, verdict="revise"):
        return {"at": at, "eventId": "ev", "target": target, "verdict": verdict, "note": note}

    def rules(self):
        return judge.read_json(rp.rules_path(self.ws), [])

    def reply(self, *rules):
        return {"rules": [{"scope": {"kind": k, "name": n}, "text": t} for k, n, t in rules]}

    def test_proposes_only_proposed_with_source(self):
        self.notes(self.fb(10, "Archie's coat is the wrong colour"))
        b = FakeBackend(queue=[self.reply(("character", "Archie", "Archie's coat is always dark green."))])
        added, done = rp.propose_rules(self.ws, b)
        self.assertEqual(done, 1)
        r = self.rules()
        self.assertEqual([x["status"] for x in r], ["proposed"])
        self.assertEqual(r[0]["source"], {"eventId": "ev", "draft": DRAFT, "note": "Archie's coat is the wrong colour"})
        self.assertEqual(r[0]["scope"], {"kind": "character", "name": "Archie"})
        self.assertIn("Archie", b.calls[0]["instruction"])

    def test_watermark_rerun_makes_zero_calls(self):
        self.notes(self.fb(10, "no text"))
        rp.propose_rules(self.ws, FakeBackend(queue=[self.reply(("global", "", "No legible text."))]))
        b = FakeBackend(queue=[])
        added, done = rp.propose_rules(self.ws, b)
        self.assertEqual((added, done, b.calls), ([], 0, []))

    def test_only_newer_notes_and_draft_notes(self):
        self.notes(self.fb(10, "old"))
        rp.propose_rules(self.ws, FakeBackend(queue=[self.reply()]))
        self.notes(self.fb(10, "old"), self.fb(20, "new"), self.fb(30, "board note", target="board"), self.fb(40, "", verdict="approve"))
        b = FakeBackend(queue=[self.reply(("global", "", "Rule new."))])
        rp.propose_rules(self.ws, b)
        self.assertEqual(len(b.calls), 1)
        self.assertIn("new", b.calls[0]["instruction"])
        self.assertEqual(rp.load_watermark(self.ws), 20)

    def test_duplicates_of_any_status_dropped(self):
        self.ws.write_json(rp.rules_path(self.ws), [
            {"id": "r1", "scope": {"kind": "global", "name": ""}, "text": "No legible text.", "status": "rejected"},
            {"id": "r2", "scope": {"kind": "plate", "name": "yard"}, "text": "Cobbles are grey.", "status": "retired"}])
        self.notes(self.fb(10, "x"))
        b = FakeBackend(queue=[self.reply(("global", "", "no legible text"), ("plate", "yard", "Cobbles are grey"),
                                          ("character", "Des", "No legible text."))])
        added, _ = rp.propose_rules(self.ws, b)
        self.assertEqual([(r["scope"]["name"], r["id"]) for r in added], [("Des", "r3")])
        self.assertEqual(len(self.rules()), 3)

    def test_failed_call_keeps_watermark_before_note(self):
        self.notes(self.fb(10, "a"), self.fb(20, "b"))
        b = FakeBackend(queue=[self.reply(("global", "", "Rule a.")), BackendError("boom")])
        added, done = rp.propose_rules(self.ws, b)
        self.assertEqual((len(added), done, rp.load_watermark(self.ws)), (1, 1, 10))

    def test_invalid_scopes_skipped_and_only_proposed(self):
        self.notes(self.fb(10, "x"))
        b = FakeBackend(queue=[self.reply(("character", "", "Nameless."), ("weird", "z", "Bad kind."), ("global", "", "Good one."))])
        rp.propose_rules(self.ws, b)
        self.assertEqual([r["text"] for r in self.rules()], ["Good one."])

    def test_cli(self):
        self.notes(self.fb(10, "x"))
        d = os.path.join(self.tmp, "fake")
        os.makedirs(d)
        with open(os.path.join(d, "propose__0.json"), "w") as f:
            json.dump(self.reply(("global", "", "Rule x.")), f)
        self.assertEqual(judge.main(["propose-rules", "--repo", self.tmp, "--backend", "fake", "--fake-replies", d]), 0)
        self.assertEqual(len(self.rules()), 1)


if __name__ == "__main__":
    unittest.main()

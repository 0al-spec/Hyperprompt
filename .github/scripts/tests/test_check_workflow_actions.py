from __future__ import annotations

import importlib.util
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).resolve().parents[1] / "check-workflow-actions.py"
SPEC = importlib.util.spec_from_file_location("check_workflow_actions", SCRIPT)
assert SPEC is not None
assert SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class WorkflowActionValidationTests(unittest.TestCase):
    def validate(self, workflow: str) -> tuple[list[str], int]:
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            workflows = root / ".github" / "workflows"
            workflows.mkdir(parents=True)
            (workflows / "ci.yml").write_text(workflow, encoding="utf-8")
            return MODULE.validate(workflows)

    def test_reviewed_major_is_accepted(self) -> None:
        failures, count = self.validate("steps:\n  - uses: actions/checkout@v6\n")
        self.assertEqual(failures, [])
        self.assertEqual(count, 1)

    def test_commit_sha_is_rejected_instead_of_skipped(self) -> None:
        failures, count = self.validate(
            "steps:\n  - uses: actions/checkout@0123456789abcdef\n"
        )
        self.assertEqual(count, 1)
        self.assertRegex(failures[0], r"reviewed <owner>/<action>@v<major> form")

    def test_mutable_branch_is_rejected_instead_of_skipped(self) -> None:
        failures, count = self.validate("steps:\n  - uses: actions/checkout@main\n")
        self.assertEqual(count, 1)
        self.assertRegex(failures[0], r"reviewed <owner>/<action>@v<major> form")

    def test_trailing_comment_is_rejected_instead_of_skipped(self) -> None:
        failures, count = self.validate(
            "steps:\n  - uses: actions/checkout@v6 # current\n"
        )
        self.assertEqual(count, 1)
        self.assertRegex(failures[0], r"reviewed <owner>/<action>@v<major> form")

    def test_unreviewed_action_is_rejected(self) -> None:
        failures, count = self.validate("steps:\n  - uses: example/action@v1\n")
        self.assertEqual(count, 1)
        self.assertRegex(failures[0], r"unreviewed action reference")

    def test_old_major_is_rejected(self) -> None:
        failures, count = self.validate(
            "steps:\n  - uses: actions/download-artifact@v7\n"
        )
        self.assertEqual(count, 1)
        self.assertRegex(failures[0], r"must be @v8 or newer")

    def test_force_flag_is_rejected(self) -> None:
        failures, count = self.validate(
            "env:\n  FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: \"true\"\n"
        )
        self.assertEqual(count, 0)
        self.assertRegex(failures[0], r"remove the temporary Node.js 24 force flag")


if __name__ == "__main__":
    unittest.main()

#!/usr/bin/env python3
"""Reject GitHub Actions references that still require the Node.js 20 runtime."""

from __future__ import annotations

import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
WORKFLOWS = ROOT / ".github" / "workflows"
USES = re.compile(r"^\s*uses:\s*([^@\s]+)@v([0-9]+)\s*$")

MINIMUM_MAJORS = {
    "SwiftyLab/setup-swift": 1,
    "actions/cache": 5,
    "actions/checkout": 6,
    "actions/deploy-pages": 5,
    "actions/download-artifact": 8,
    "actions/github-script": 9,
    "actions/setup-node": 6,
    "actions/upload-artifact": 7,
    "actions/upload-pages-artifact": 5,
}


def main() -> int:
    failures: list[str] = []
    action_count = 0

    for path in sorted(WORKFLOWS.glob("*.y*ml")):
        relative = path.relative_to(ROOT)
        text = path.read_text(encoding="utf-8")
        if "FORCE_JAVASCRIPT_ACTIONS_TO_NODE24" in text:
            failures.append(f"{relative}: remove the temporary Node.js 24 force flag")
        if "swift-actions/setup-swift@" in text:
            failures.append(
                f"{relative}: use the Node.js 24-backed SwiftyLab/setup-swift action"
            )

        for line_number, line in enumerate(text.splitlines(), start=1):
            match = USES.match(line)
            if match is None:
                continue
            action_count += 1
            action, major_text = match.groups()
            minimum = MINIMUM_MAJORS.get(action)
            if minimum is None:
                failures.append(
                    f"{relative}:{line_number}: unreviewed action reference {action!r}"
                )
                continue
            major = int(major_text)
            if major < minimum:
                failures.append(
                    f"{relative}:{line_number}: {action}@v{major} must be "
                    f"@v{minimum} or newer"
                )

    if failures:
        raise SystemExit("\n".join(failures))
    print(f"Workflow actions are Node.js 24-ready ({action_count} references)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/usr/bin/env python3
"""Validate that release-facing metadata agrees with the canonical version."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
VERSION_SOURCE = ROOT / "Sources" / "Core" / "HyperpromptVersion.swift"
SEMVER = re.compile(
    r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)"
)


def current_version() -> str:
    source = VERSION_SOURCE.read_text(encoding="utf-8")
    match = re.search(r'public static let current = "([^"]+)"', source)
    if match is None:
        raise SystemExit("HyperpromptVersion.current is missing")
    version = match.group(1)
    if SEMVER.fullmatch(version) is None:
        raise SystemExit(f"HyperpromptVersion.current is not stable SemVer: {version!r}")
    return version


def require(path: Path, token: str) -> None:
    if token not in path.read_text(encoding="utf-8"):
        relative = path.relative_to(ROOT)
        raise SystemExit(f"{relative} is missing release token {token!r}")


def validate(version: str) -> None:
    notes = (
        ROOT
        / "Sources"
        / "CLI"
        / "Documentation.docc"
        / "RELEASES"
        / f"v{version}"
        / f"RELEASE_NOTES_v{version}.md"
    )
    if not notes.is_file():
        raise SystemExit(f"release notes are missing: {notes.relative_to(ROOT)}")

    require(ROOT / "CHANGELOG.md", f"## [{version}] - ")
    require(ROOT / "README.md", f"# Hyperprompt Compiler v{version.rsplit('.', 1)[0]}")
    require(
        ROOT / "README.md",
        f"https://github.com/0al-spec/Hyperprompt/releases/tag/v{version}",
    )
    require(notes, f"# Hyperprompt Compiler v{version}")
    require(notes, f"**Tag:** `v{version}`")
    artifact_contract = (
        ROOT
        / "Sources"
        / "CLI"
        / "Documentation.docc"
        / "SERVER_ARTIFACT_CONTRACT.md"
    )
    require(artifact_contract, '"compiler_version": "<stable SemVer>"')
    require(artifact_contract, "matches `compiler_version`")

    source_expectations = {
        ROOT / "Sources" / "CLI" / "Hyperprompt.swift": (
            "version: HyperpromptVersion.current",
        ),
        ROOT / "Sources" / "CompilerDriver" / "CompilerDriver.swift": (
            "version: String = HyperpromptVersion.current",
        ),
        ROOT / "Sources" / "EditorEngine" / "EditorCompiler.swift": (
            "version: String = HyperpromptVersion.current",
        ),
    }
    for path, tokens in source_expectations.items():
        for token in tokens:
            require(path, token)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--print-version",
        action="store_true",
        help="print the canonical version after validation",
    )
    args = parser.parse_args()

    version = current_version()
    validate(version)
    if args.print_version:
        print(version)
    else:
        print(f"Release metadata is consistent for v{version}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

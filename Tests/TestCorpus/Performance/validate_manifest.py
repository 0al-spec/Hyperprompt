#!/usr/bin/env python3
"""
Manifest Validation Script

This script validates Hyperprompt Compiler manifest JSON files against
the specification defined in Sources/Emitter/Manifest.swift.

Requirements:
- All JSON keys alphabetically sorted at all levels
- Timestamp in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ)
- Sources array sorted by 'path' field
- File ends with exactly one LF character
- Valid JSON structure

Usage:
    python3 validate_manifest.py <manifest.json>
"""

import json
import sys
from datetime import datetime
from pathlib import Path


def validate_alphabetical_keys(obj, path="root"):
    """Recursively validate that all dictionary keys are alphabetically sorted."""
    if isinstance(obj, dict):
        keys = list(obj.keys())
        sorted_keys = sorted(keys)
        if keys != sorted_keys:
            return False, f"Keys not sorted at {path}: {keys} should be {sorted_keys}"

        # Recursively check nested objects
        for key, value in obj.items():
            is_valid, msg = validate_alphabetical_keys(value, f"{path}.{key}")
            if not is_valid:
                return False, msg

    elif isinstance(obj, list):
        # Check each item in list
        for i, item in enumerate(obj):
            is_valid, msg = validate_alphabetical_keys(item, f"{path}[{i}]")
            if not is_valid:
                return False, msg

    return True, "OK"


def validate_iso8601_timestamp(timestamp):
    """Validate ISO 8601 timestamp format."""
    try:
        # Expected format: YYYY-MM-DDTHH:MM:SSZ
        dt = datetime.strptime(timestamp, "%Y-%m-%dT%H:%M:%SZ")
        return True, "OK"
    except ValueError as e:
        return False, f"Invalid ISO 8601 timestamp: {e}"


def validate_sources_sorted(sources):
    """Validate that sources array is sorted by 'path' field."""
    if not sources:
        return True, "OK (empty)"

    paths = [entry.get("path") for entry in sources]
    sorted_paths = sorted(paths)

    if paths != sorted_paths:
        return False, f"Sources not sorted by path: {paths} should be {sorted_paths}"

    return True, "OK"


def validate_manifest_structure(manifest):
    """Validate required fields exist."""
    required_fields = ["root", "sources", "timestamp", "version"]

    for field in required_fields:
        if field not in manifest:
            return False, f"Missing required field: {field}"

    # Validate sources structure
    if not isinstance(manifest["sources"], list):
        return False, "'sources' must be an array"

    # Validate each source entry
    for i, entry in enumerate(manifest["sources"]):
        required_entry_fields = ["path", "sha256", "size", "type"]
        for field in required_entry_fields:
            if field not in entry:
                return False, f"sources[{i}] missing field: {field}"

        # Validate type is valid
        if entry["type"] not in ["hypercode", "markdown"]:
            return False, f"sources[{i}] invalid type: {entry['type']}"

    return True, "OK"


def validate_file_ending(file_path):
    """Validate file ends with exactly one LF."""
    with open(file_path, 'rb') as f:
        content = f.read()

    if not content:
        return False, "Empty file"

    if content[-1:] != b'\n':
        return False, "File does not end with LF"

    if content[-2:-1] == b'\n':
        return False, "File ends with multiple LFs"

    return True, "OK"


def validate_manifest(file_path):
    """Main validation function."""
    print(f"Validating manifest: {file_path}")
    print("=" * 60)

    results = []
    all_passed = True

    # Check 1: Valid JSON
    try:
        with open(file_path, 'r') as f:
            manifest = json.load(f)
        results.append(("✓", "Valid JSON structure"))
    except json.JSONDecodeError as e:
        results.append(("✗", f"Invalid JSON: {e}"))
        all_passed = False
        manifest = None
    except FileNotFoundError:
        results.append(("✗", f"File not found: {file_path}"))
        return False

    if manifest is None:
        for status, msg in results:
            print(f"{status} {msg}")
        return False

    # Check 2: File ending
    is_valid, msg = validate_file_ending(file_path)
    if is_valid:
        results.append(("✓", "File ends with exactly one LF"))
    else:
        results.append(("✗", f"File ending validation failed: {msg}"))
        all_passed = False

    # Check 3: Required structure
    is_valid, msg = validate_manifest_structure(manifest)
    if is_valid:
        results.append(("✓", "All required fields present"))
    else:
        results.append(("✗", f"Structure validation failed: {msg}"))
        all_passed = False

    # Check 4: Alphabetically sorted keys
    is_valid, msg = validate_alphabetical_keys(manifest)
    if is_valid:
        results.append(("✓", "All JSON keys alphabetically sorted"))
    else:
        results.append(("✗", f"Key sorting validation failed: {msg}"))
        all_passed = False

    # Check 5: ISO 8601 timestamp
    if "timestamp" in manifest:
        is_valid, msg = validate_iso8601_timestamp(manifest["timestamp"])
        if is_valid:
            results.append(("✓", f"Valid ISO 8601 timestamp: {manifest['timestamp']}"))
        else:
            results.append(("✗", msg))
            all_passed = False

    # Check 6: Sources sorted by path
    if "sources" in manifest:
        is_valid, msg = validate_sources_sorted(manifest["sources"])
        if is_valid:
            results.append(("✓", f"Sources sorted by path ({len(manifest['sources'])} entries)"))
        else:
            results.append(("✗", msg))
            all_passed = False

    # Print results
    print()
    for status, msg in results:
        print(f"{status} {msg}")

    print()
    print("=" * 60)
    if all_passed:
        print("✓ MANIFEST VALIDATION PASSED")
    else:
        print("✗ MANIFEST VALIDATION FAILED")

    return all_passed


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 validate_manifest.py <manifest.json>")
        sys.exit(1)

    manifest_file = sys.argv[1]
    success = validate_manifest(manifest_file)
    sys.exit(0 if success else 1)

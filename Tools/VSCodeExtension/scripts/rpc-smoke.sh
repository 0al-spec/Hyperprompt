#!/usr/bin/env bash
set -euo pipefail

entry_file="${1:-}"
workspace_root="${2:-}"
hyperprompt_bin="${3:-}"

if [[ -z "$entry_file" ]]; then
  echo "usage: $0 /path/to/file.hc [workspace_root] [hyperprompt_bin]" >&2
  exit 1
fi

if [[ "${entry_file##*.}" != "hc" ]]; then
  echo "error: entry file must end with .hc" >&2
  exit 1
fi

entry_dir="$(cd "$(dirname "$entry_file")" && pwd)"
entry_file_abs="${entry_dir}/$(basename "$entry_file")"

if [[ -z "$workspace_root" ]]; then
  workspace_root="$entry_dir"
fi

if [[ -z "$hyperprompt_bin" ]]; then
  hyperprompt_bin="$(pwd)/.build/debug/hyperprompt"
fi

if [[ ! -x "$hyperprompt_bin" ]]; then
  echo "error: hyperprompt binary not found or not executable: $hyperprompt_bin" >&2
  echo "hint: swift build --traits Editor" >&2
  exit 1
fi

payload="$(python3 - <<'PY' "$entry_file_abs" "$workspace_root"
import json
import sys

entry = sys.argv[1]
root = sys.argv[2]
print(json.dumps({
    "jsonrpc": "2.0",
    "id": 1,
    "method": "editor.compile",
    "params": {
        "entryFile": entry,
        "workspaceRoot": root,
    },
}))
PY
)"

printf '%s\n' "$payload" | "$hyperprompt_bin" editor-rpc

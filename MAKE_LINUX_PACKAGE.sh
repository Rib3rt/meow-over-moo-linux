#!/bin/sh
set -eu
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
python3 "$SCRIPT_DIR/scripts/build_native_linux_package.py" \
  --source-project "$SCRIPT_DIR" \
  --linux-runtime-dir "$SCRIPT_DIR/LOVE_11_5_LINUX_RUNTIME_DROP" \
  --output-parent "$(dirname "$SCRIPT_DIR")"

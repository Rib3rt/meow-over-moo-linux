#!/bin/sh
set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
"$SCRIPT_DIR/DECK_BUILD_NATIVE.sh"
cd "$SCRIPT_DIR"
./MAKE_LINUX_PACKAGE.sh

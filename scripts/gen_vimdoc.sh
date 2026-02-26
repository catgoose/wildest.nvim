#!/usr/bin/env bash
# Generate vimdoc from LuaCATS annotations using lemmy-help
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT="$ROOT_DIR/doc/wildest.txt"

# Check for lemmy-help
if command -v lemmy-help &>/dev/null; then
  LEMMY=lemmy-help
elif [ -x "$ROOT_DIR/deps/lemmy-help" ]; then
  LEMMY="$ROOT_DIR/deps/lemmy-help"
else
  echo "lemmy-help not found. Install via:"
  echo "  cargo install lemmy-help"
  echo "  or download from https://github.com/numToStr/lemmy-help/releases"
  exit 1
fi

echo "Generating vimdoc with $LEMMY..."

# Ordered list of source files for doc generation
# Priority A — public API first, then internals
$LEMMY -f -a \
  "$ROOT_DIR/lua/wildest/init.lua" \
  "$ROOT_DIR/lua/wildest/config.lua" \
  "$ROOT_DIR/lua/wildest/state.lua" \
  "$ROOT_DIR/lua/wildest/util.lua" \
  "$ROOT_DIR/lua/wildest/cache.lua" \
  "$ROOT_DIR/lua/wildest/pipeline/init.lua" \
  "$ROOT_DIR/lua/wildest/filter/init.lua" \
  "$ROOT_DIR/lua/wildest/highlight/init.lua" \
  "$ROOT_DIR/lua/wildest/renderer/init.lua" \
  > "$OUT"

echo "Generated $OUT"

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f "CODEX.md" ] || [ ! -d "RenderCoreMetal" ]; then
  echo "Refusing to run outside the TelluricEngine repository root." >&2
  exit 64
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$ROOT/.build/clang-module-cache"
export SWIFT_MODULE_CACHE_PATH="$ROOT/.build/swift-module-cache"

mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFT_MODULE_CACHE_PATH"

/usr/bin/xcrun swift test \
  --package-path "$ROOT/RenderCoreMetal" \
  --scratch-path "$ROOT/RenderCoreMetal/.build"

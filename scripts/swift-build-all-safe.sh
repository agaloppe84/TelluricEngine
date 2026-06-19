#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f "CODEX.md" ]; then
  echo "Refusing to run outside the TelluricEngine repository root." >&2
  exit 64
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
export CLANG_MODULE_CACHE_PATH="$ROOT/.build/clang-module-cache"
export SWIFT_MODULE_CACHE_PATH="$ROOT/.build/swift-module-cache"

mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFT_MODULE_CACHE_PATH"

build_package() {
  local package_name="$1"
  local package_path="$ROOT/$package_name"

  if [ ! -f "$package_path/Package.swift" ]; then
    echo "Missing Swift package: $package_name" >&2
    exit 1
  fi

  echo "Building $package_name"
  /usr/bin/xcrun swift build \
    --package-path "$package_path" \
    --scratch-path "$package_path/.build"
}

build_package "EngineCore"
build_package "RenderCoreMetal"
build_package "AudioRuntime"

echo "All Swift packages built."


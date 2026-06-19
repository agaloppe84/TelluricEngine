#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f "CODEX.md" ] || [ ! -f "TELLURIC_ENGINE_FINAL_ARCHITECTURE.md" ]; then
  echo "Refusing to run outside the TelluricEngine repository root." >&2
  exit 64
fi

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

echo "Repository: $ROOT"
echo "DEVELOPER_DIR: $DEVELOPER_DIR"
echo

echo "Git status:"
git status --short
echo

required_dirs=(
  "EngineCore"
  "RenderCoreMetal"
  "AudioRuntime"
  "TelluricTools"
  "Shaders"
  "SamplesTiny"
  "LocalAssets"
  "RuntimeApp"
  "scripts"
  "docs/reference"
)

missing=0
for dir in "${required_dirs[@]}"; do
  if [ ! -d "$dir" ]; then
    echo "Missing required directory: $dir" >&2
    missing=1
  fi
done

required_files=(
  ".gitignore"
  "README.md"
  "EngineCore/Package.swift"
  "RenderCoreMetal/Package.swift"
  "AudioRuntime/Package.swift"
)

for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "Missing required file: $file" >&2
    missing=1
  fi
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "Xcode tool lookup through local DEVELOPER_DIR:"
if ! /usr/bin/xcrun --find xcodebuild; then
  echo "xcodebuild was not found through DEVELOPER_DIR." >&2
  exit 1
fi
echo

echo "Ruby/Rails dependency marker check:"
ruby_markers="$(find "$ROOT" -maxdepth 3 \( -name "Gemfile" -o -name "Gemfile.lock" -o -name "*.gemspec" -o -name ".ruby-version" \) -print)"
if [ -n "$ruby_markers" ]; then
  echo "$ruby_markers" >&2
  echo "Telluric must not be configured as a Ruby/Rails project." >&2
  exit 1
fi
echo "No Ruby/Rails dependency markers found."
echo

echo "Detected Xcode projects under RuntimeApp:"
find "$ROOT/RuntimeApp" -maxdepth 4 -name "*.xcodeproj" -type d -print | sort
echo

echo "Preflight complete."


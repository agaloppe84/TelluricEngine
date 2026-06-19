#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f "CODEX.md" ]; then
  echo "Refusing to run outside the TelluricEngine repository root." >&2
  exit 64
fi

failed=0

echo "Checking safe scripts for forbidden global mutation commands."
for script in "$ROOT"/scripts/*.sh; do
  base="$(basename "$script")"
  if [ "$base" = "verify-no-global-mutations.sh" ]; then
    continue
  fi

  if /usr/bin/grep -En '(^|[;&|[:space:]])sudo([[:space:]]|$)|(^|[;&|[:space:]])xcode-select([[:space:]]|$)|(^|[;&|[:space:]])brew[[:space:]]+(update|upgrade|install|uninstall|cleanup)([[:space:]]|$)|(^|[;&|[:space:]])gem[[:space:]]+(install|update)([[:space:]]|$)|(^|[;&|[:space:]])bundle[[:space:]]+update([[:space:]]|$)|(^|[;&|[:space:]])bundle[[:space:]]+install[[:space:]]+--global([[:space:]]|$)|(^|[;&|[:space:]])npm[[:space:]]+install[[:space:]]+-g([[:space:]]|$)|(^|[;&|[:space:]])pnpm[[:space:]]+add[[:space:]]+-g([[:space:]]|$)|(^|[;&|[:space:]])yarn[[:space:]]+global([[:space:]]|$)|(^|[;&|[:space:]])asdf[[:space:]]+install([[:space:]]|$)|(^|[;&|[:space:]])mise[[:space:]]+install([[:space:]]|$)|(^|[;&|[:space:]])rbenv[[:space:]]+install([[:space:]]|$)|(^|[;&|[:space:]])rvm[[:space:]]+install([[:space:]]|$)' "$script"; then
    echo "Forbidden command pattern found in $script" >&2
    failed=1
  fi
done

echo "Checking EngineCore forbidden imports."
if /usr/bin/grep -R -n -E '^import[[:space:]]+(SwiftUI|AppKit|UIKit|Metal|MetalKit|RealityKit|SceneKit|SpriteKit|GameController|AVFoundation)' "$ROOT/EngineCore/Sources/EngineCore"; then
  echo "Forbidden import found in EngineCore." >&2
  failed=1
fi

require_gitignore_entry() {
  local entry="$1"
  if ! /usr/bin/grep -Fxq "$entry" "$ROOT/.gitignore"; then
    echo "Missing .gitignore entry: $entry" >&2
    failed=1
  fi
}

echo "Checking .gitignore local output coverage."
require_gitignore_entry ".build/"
require_gitignore_entry "**/.build/"
require_gitignore_entry ".derivedData/"
require_gitignore_entry "LocalAssets/*"
require_gitignore_entry "!LocalAssets/.gitkeep"
require_gitignore_entry ".bundle/"
require_gitignore_entry "vendor/bundle/"

if [ "$failed" -ne 0 ]; then
  exit 1
fi

echo "No global mutation patterns detected."


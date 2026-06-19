#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-build}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ ! -f "CODEX.md" ]; then
  echo "Refusing to run outside the TelluricEngine repository root." >&2
  exit 64
fi

case "$ACTION" in
  build|test|clean)
    ;;
  *)
    echo "Refusing unsupported xcodebuild action: $ACTION" >&2
    echo "Allowed actions: build, test, clean" >&2
    exit 64
    ;;
esac

export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

PROJECT_CANDIDATES="$(find "$ROOT/RuntimeApp" -maxdepth 4 -name "*.xcodeproj" -type d -print | sort)"

if [ -z "$PROJECT_CANDIDATES" ]; then
  echo "No Xcode project found under RuntimeApp/." >&2
  echo "Create or open the RuntimeApp project in Xcode, then rerun this script." >&2
  exit 1
fi

PROJECT_PATH="$(printf "%s\n" "$PROJECT_CANDIDATES" | awk '/TelluricRuntimeApp\.xcodeproj$/ { print; exit }')"
if [ -z "$PROJECT_PATH" ]; then
  PROJECT_PATH="$(printf "%s\n" "$PROJECT_CANDIDATES" | sed -n '1p')"
fi

PROJECT_COUNT="$(printf "%s\n" "$PROJECT_CANDIDATES" | sed '/^$/d' | wc -l | tr -d ' ')"
if [ "$PROJECT_COUNT" -gt 1 ]; then
  echo "Multiple Xcode projects detected. Using: $PROJECT_PATH" >&2
fi

PROJECT_NAME="$(basename "$PROJECT_PATH" .xcodeproj)"
SCHEME="${TELLURIC_XCODE_SCHEME:-$PROJECT_NAME}"
DERIVED_DATA="$ROOT/.derivedData/TelluricRuntimeApp"

mkdir -p "$DERIVED_DATA"

echo "Project: $PROJECT_PATH"
echo "Scheme: $SCHEME"
echo "DerivedData: $DERIVED_DATA"

/usr/bin/xcrun xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -destination "platform=macOS" \
  -derivedDataPath "$DERIVED_DATA" \
  "$ACTION"


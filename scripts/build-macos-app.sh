#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build"
VERSION="$(/usr/bin/plutil -extract version raw -o - "$PROJECT_ROOT/package.json")"
APP_ROOT="$BUILD_ROOT/GrokRouter.app"
CONTENTS="$APP_ROOT/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ARCHIVE="$BUILD_ROOT/grokbot-router-payload-${VERSION}.tgz"
ZIP_PATH="$BUILD_ROOT/grokrouter-${VERSION}-macos.zip"

create_zip() {
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_ROOT" "$ZIP_PATH"
}

bash "$PROJECT_ROOT/scripts/build-payload.sh" >/dev/null

rm -rf "$APP_ROOT"
mkdir -p "$MACOS" "$RESOURCES/grokrouter-native-skills"
cp "$PROJECT_ROOT/installer/Info.plist" "$CONTENTS/Info.plist"
cp "$ARCHIVE" "$RESOURCES/grokbot-router-payload.tgz"
cp "$PROJECT_ROOT/installer/Assets/AppIcon.icns" "$RESOURCES/AppIcon.icns"
cp "$PROJECT_ROOT/installer/native-workflow-registration.js" "$RESOURCES/native-workflow-registration.js"
cp -R "$PROJECT_ROOT/skills/." "$RESOURCES/grokrouter-native-skills/"

swiftc \
  -swift-version 5 \
  -target arm64-apple-macosx12.0 \
  -O \
  -framework AppKit \
  -framework Vision \
  -framework CryptoKit \
  -framework Security \
  "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift" \
  -o "$MACOS/GrokBotRouterInstaller"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"

SIGNING_IDENTITY="${ROUTER_CODESIGN_IDENTITY:--}"
codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_ROOT"
codesign --verify --deep --strict "$APP_ROOT"

if [[ "${ROUTER_BUILD_APP_ONLY:-0}" == "1" ]]; then
  printf '%s\n' "$APP_ROOT"
  exit 0
fi

create_zip

if [[ -n "${ROUTER_NOTARY_PROFILE:-}" ]]; then
  if [[ "$SIGNING_IDENTITY" == "-" ]]; then
    printf 'ERROR: notarization requires ROUTER_CODESIGN_IDENTITY\n' >&2
    exit 1
  fi
  xcrun notarytool submit "$ZIP_PATH" \
    --keychain-profile "$ROUTER_NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$APP_ROOT"
  create_zip
  codesign --verify --deep --strict "$APP_ROOT"
  xcrun stapler validate "$APP_ROOT"
fi

(
  cd "$BUILD_ROOT"
  shasum -a 256 "$(basename "$ZIP_PATH")"
) > "$ZIP_PATH.sha256"

printf '%s\n' "$APP_ROOT" "$ZIP_PATH"

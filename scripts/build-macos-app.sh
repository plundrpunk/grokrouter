#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_ROOT="$PROJECT_ROOT/build"
VERSION="$(cd "$PROJECT_ROOT" && node -p "require('./package.json').version")"
APP_ROOT="$BUILD_ROOT/GrokRouter.app"
CONTENTS="$APP_ROOT/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"
ARCHIVE="$BUILD_ROOT/grokbot-router-payload-${VERSION}.tgz"
ZIP_PATH="$BUILD_ROOT/grokrouter-${VERSION}-macos.zip"
DMG_PATH="$BUILD_ROOT/grokrouter-${VERSION}-macos.dmg"
DMG_STAGE="$(mktemp -d -t grokrouter-dmg.XXXXXX)"

cleanup() {
  rm -rf "$DMG_STAGE"
}
trap cleanup EXIT

create_zip() {
  rm -f "$ZIP_PATH"
  ditto -c -k --sequesterRsrc --keepParent "$APP_ROOT" "$ZIP_PATH"
}

create_dmg() {
  rm -rf "$DMG_STAGE"/*
  ditto "$APP_ROOT" "$DMG_STAGE/GrokRouter.app"
  ln -s /Applications "$DMG_STAGE/Applications"
  rm -f "$DMG_PATH"
  hdiutil create \
    -volname "GrokRouter" \
    -srcfolder "$DMG_STAGE" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -ov \
    "$DMG_PATH" \
    >/dev/null
  hdiutil verify "$DMG_PATH" >/dev/null
}

bash "$PROJECT_ROOT/scripts/build-payload.sh" >/dev/null

rm -rf "$APP_ROOT"
mkdir -p "$MACOS" "$RESOURCES"
cp "$PROJECT_ROOT/installer/Info.plist" "$CONTENTS/Info.plist"
cp "$ARCHIVE" "$RESOURCES/grokbot-router-payload.tgz"
cp "$PROJECT_ROOT/installer/Assets/AppIcon.icns" "$RESOURCES/AppIcon.icns"

swiftc \
  -swift-version 5 \
  -target arm64-apple-macosx12.0 \
  -O \
  -framework AppKit \
  -framework Vision \
  -framework CryptoKit \
  "$PROJECT_ROOT/installer/GrokBotRouterInstaller.swift" \
  -o "$MACOS/GrokBotRouterInstaller"

/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"

SIGNING_IDENTITY="${ROUTER_CODESIGN_IDENTITY:--}"
codesign --force --deep --options runtime --sign "$SIGNING_IDENTITY" "$APP_ROOT"
codesign --verify --deep --strict "$APP_ROOT"

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

create_dmg

if [[ -n "${ROUTER_NOTARY_PROFILE:-}" ]]; then
  xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$ROUTER_NOTARY_PROFILE" \
    --wait
  xcrun stapler staple "$DMG_PATH"
  xcrun stapler validate "$DMG_PATH"
fi

(
  cd "$BUILD_ROOT"
  shasum -a 256 "$(basename "$ZIP_PATH")"
) > "$ZIP_PATH.sha256"
(
  cd "$BUILD_ROOT"
  shasum -a 256 "$(basename "$DMG_PATH")"
) > "$DMG_PATH.sha256"

printf '%s\n' "$APP_ROOT" "$DMG_PATH" "$ZIP_PATH"

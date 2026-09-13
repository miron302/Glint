#!/bin/bash
# Builds Glint and wraps it in a proper .app bundle.
# Run this on macOS from the project root: ./build.sh
set -e

APP_NAME="Glint"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"

echo "==> Building ${APP_NAME} (release)…"
swift build -c release

echo "==> Assembling ${APP_BUNDLE}…"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"
cp "Resources/Info.plist" "${APP_BUNDLE}/Contents/Info.plist"

if [ -f "Resources/AppIcon.icns" ]; then
  cp "Resources/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
else
  echo "    (no AppIcon.icns found in Resources/ — app will use a default icon)"
fi

echo "==> Ad-hoc code signing…"
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "==> Done. Move ${APP_BUNDLE} to /Applications and double-click to run."
echo "    First launch: right-click > Open, since it's not notarized."

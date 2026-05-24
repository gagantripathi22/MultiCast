#!/bin/bash

set -e

APP_NAME="MultiCast"
APP_BUNDLE="${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME}..."

# Create app bundle structure
rm -rf "${APP_BUNDLE}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Compile Swift code
swiftc -target x86_64-apple-macosx13.0 -target arm64-apple-macosx13.0 \
    -framework SwiftUI -framework AppKit -framework CoreAudio -framework Combine \
    -parse-as-library \
    -o "${MACOS_DIR}/${APP_NAME}" \
    Sources/App.swift Sources/AudioDeviceManager.swift

# Copy Info.plist and Icon
cp Info.plist "${CONTENTS_DIR}/"
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "${RESOURCES_DIR}/"
fi

# Codesign the app bundle
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "Build successful! You can run the app using: open ${APP_BUNDLE}"

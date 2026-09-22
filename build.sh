#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
APP="$PWD/dist/KeyTrace.app"
mkdir -p "$APP/Contents/MacOS"
xcrun swiftc -swift-version 5 -O -target arm64-apple-macosx13.0 -module-cache-path /private/tmp/keytrace-swift-cache main.swift Localization.swift Soundtrack.swift Keyboard.swift KeyboardView.swift EventTimeline.swift InputRecording.swift VideoRenderer.swift VideoExport.swift -o "$APP/Contents/MacOS/KeyTrace" -framework Cocoa -framework SwiftUI -framework ServiceManagement -framework IOKit -framework SceneKit -framework AVFoundation -framework Metal -framework AudioToolbox
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>KeyTrace</string>
<key>CFBundleIdentifier</key><string>app.keytrace.mac</string>
<key>CFBundleName</key><string>KeyTrace</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.4.3</string>
<key>CFBundleVersion</key><string>15</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSInputMonitoringUsageDescription</key><string>保存键鼠按下与松开的时间和键位，用于本机动画回放；键位序列可能推断输入内容。</string>
</dict></plist>
PLIST
mkdir -p "$APP/Contents/Resources"
bash scripts/build-icon.sh "$APP/Contents/Resources/AppIcon.icns"
cp Resources/AppIcon.svg "$APP/Contents/Resources/"
cp Resources/layouts.json "$APP/Contents/Resources/"
cp Resources/localizations.json "$APP/Contents/Resources/"
cp -R Resources/*.lproj "$APP/Contents/Resources/"
signing_identity="${SIGNING_IDENTITY:--}"
if [[ "$signing_identity" == "-" ]]; then
    echo 'Local ad-hoc build: replacing an installed version may invalidate Input Monitoring.' >&2
    codesign --force --sign - "$APP"
else
    codesign --force --options runtime --timestamp --sign "$signing_identity" "$APP"
fi
codesign --verify --strict "$APP"
echo "$APP"

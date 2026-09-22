#!/bin/bash
set -euo pipefail
# Explicitly select a published release; never silently fall back to GitHub /latest.
repo="nope-gao/KeyTrace"
version="v1.0.0"
case "${1:-}" in
    "") ;;
    --version) version="${2:?Missing version}"; shift 2 ;;
    *) echo 'Usage: bash install.sh [--version v1.0.0]' >&2; exit 1 ;;
esac
[[ $# == 0 && "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-beta\.[0-9]+)?$ ]] || { echo 'Invalid version or arguments.' >&2; exit 1; }
echo 'Ad-hoc signed, not notarized by Apple. Updates may require Input Monitoring authorization again.'
echo '临时签名、未经 Apple 公证；更新可能需要重新授权输入监控。'
if [[ "$(uname -s)" != Darwin || "$(uname -m)" != arm64 ]]; then
    echo 'Requires an Apple Silicon Mac. / 需要 Apple Silicon Mac。' >&2
    exit 1
fi
major="$(sw_vers -productVersion | cut -d. -f1)"
if (( major < 13 )); then
    echo 'Requires macOS 13 or newer. / 需要 macOS 13 或更新版本。' >&2
    exit 1
fi
if pgrep -x KeyTrace >/dev/null || pgrep -x XAssistantMac >/dev/null; then
    echo 'Quit any running keyboard recorder before installing. / 请先退出正在运行的键盘记录应用。' >&2
    exit 1
fi
work="$(mktemp -d)"
stage=""
app="$HOME/Applications/KeyTrace.app"
cleanup() {
    if [[ -n "$stage" && -d "$stage/previous.app" && ! -e "$app" ]]; then
        mv "$stage/previous.app" "$app"
    fi
    rm -rf "$work"
    if [[ -n "$stage" ]]; then rm -rf "$stage"; fi
}
trap cleanup EXIT
curl --fail --silent --show-error --location --retry 3 "https://api.github.com/repos/$repo/releases/tags/$version" -o "$work/release.json" || {
    echo 'No downloadable release is available, or GitHub could not be reached. / 暂无可下载版本，或无法连接 GitHub。' >&2
    exit 1
}
actual_tag="$(plutil -extract tag_name raw -o - "$work/release.json")"
[[ "$actual_tag" == "$version" ]] || { echo 'Release tag mismatch.' >&2; exit 1; }
prerelease="$(plutil -extract prerelease raw -o - "$work/release.json")"
if [[ "$version" == *-beta.* && "$prerelease" != true ]]; then echo 'Expected a Pre-release.' >&2; exit 1; fi
if [[ "$version" != *-beta.* && "$prerelease" != false ]]; then echo 'Expected a release, not a Pre-release.' >&2; exit 1; fi
draft="$(plutil -extract draft raw -o - "$work/release.json")"
[[ "$draft" == false ]] || { echo 'Refusing a draft release.' >&2; exit 1; }
url="https://github.com/$repo/releases/download/$version"
for file in KeyTrace-arm64.zip SHA256SUMS; do
    curl --fail --silent --show-error --location --retry 3 "$url/$file" -o "$work/$file"
done
# Verify only the named app archive; never treat arbitrary checksum paths as input.
expected="$(awk '$2 == "KeyTrace-arm64.zip" {print $1}' "$work/SHA256SUMS")"
[[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || { echo 'Missing or ambiguous app checksum.' >&2; exit 1; }
actual="$(shasum -a 256 "$work/KeyTrace-arm64.zip" | awk '{print $1}')"
[[ "$actual" == "$expected" ]] || { echo 'App checksum mismatch.' >&2; exit 1; }
ditto -x -k "$work/KeyTrace-arm64.zip" "$work/unpacked"
sourceApp="$work/unpacked/KeyTrace.app"
codesign --verify --deep --strict "$sourceApp"
bundleID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$sourceApp/Contents/Info.plist")"
[[ "$bundleID" == app.keytrace.mac ]] || { echo 'Unexpected app bundle.' >&2; exit 1; }
appVersion="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$sourceApp/Contents/Info.plist")"
requestedVersion="${version#v}"; requestedVersion="${requestedVersion%%-beta.*}"
[[ "$appVersion" == "$requestedVersion" ]] || { echo 'App/release version mismatch.' >&2; exit 1; }
# TCC grants are bound to a code requirement, not just the bundle ID or filename.
# Test the downloaded app against the installed app's requirement before replacing anything.
if [[ -d "$app" ]]; then
    if diff -qr "$sourceApp" "$app" >/dev/null; then
        echo "Already installed: $version. No files changed."; exit 0
    fi
    current_requirement="$(codesign -d -r- "$app" 2>&1 | sed -n -E 's/^#? ?designated => //p')"
    if [[ -z "$current_requirement" ]] || ! codesign --verify --strict --test-requirement "=$current_requirement" "$sourceApp" 2>/dev/null; then
        echo 'Update stopped: the new signing identity would invalidate Input Monitoring. Your installed app and recordings are unchanged.' >&2
        echo '已停止更新：新版签名不兼容现有输入监控授权，当前应用和记录均未改动。' >&2
        echo 'Use a release signed with the same Developer ID. Changing signing identity requires authorizing the new app once in System Settings.' >&2
        exit 1
    fi
fi
mkdir -p "$HOME/Applications"
stage="$(mktemp -d "$HOME/Applications/.keytrace-install.XXXXXX")"
ditto "$sourceApp" "$stage/new.app"
if [[ -e "$app" ]]; then mv "$app" "$stage/previous.app"; fi
mv "$stage/new.app" "$app"
printf 'Installed %s: %s\n' "$version" "$app"
echo 'Open the app and enable Input Monitoring. / 打开应用并开启输入监控。'
echo 'If macOS blocks it, use System Settings → Privacy & Security → Open Anyway after reviewing the app.'
open "$app"

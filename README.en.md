# KeyTrace

[简体中文](README.md) | [繁體中文](README.zh-Hant.md) | **English** | [日本語](README.ja.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md)

A local macOS keyboard and mouse activity tracker with animated 3D heatmap video exports.

Adapted from the functionality and ideas of [xuhk/XAssistant](https://github.com/xuhk/XAssistant), reimplemented natively in Swift. This is an unofficial macOS version; no upstream Windows source code or assets were copied, and this project is not affiliated with the original author. Licensed under the [MIT License](LICENSE).

## Features

- Track keyboard and mouse activity in the background from the menu bar, with daily statistics and keyboard heatmaps.
- Detect built-in and external keyboards, with MacBook and full-size Mac layouts and manual selection.
- Select a start and end time, with Earliest and Now shortcuts.
- Export animated presses and cumulative heatmaps to Downloads as 1080p, 30 fps MP4 videos, automatically compressing idle gaps.
- Include or exclude mouse clicks; choose speeds from 0.5× to 256×, including 128×.
- Scale heatmap colors dynamically against the current highest cumulative press count, or use the final highest count in the selected range as a fixed maximum.
- Hold the final heatmap for five seconds while the camera slowly rotates.
- Play a synchronized sound for every press, with a distinct timbre per physical key and keyboard, mechanical, soft, or silent presets.

## Install

Public beta **v0.4.2-beta.1**; app **0.4.2, build 14**. Requires **Apple Silicon (arm64), macOS 13+**. Intel is unsupported. **Ad-hoc signed, not notarized by Apple; updates may require authorization again.**

Download the [app ZIP](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.2-beta.1/KeyTrace-arm64.zip) and [SHA256SUMS](https://github.com/nope-gao/KeyTrace/releases/download/v0.4.2-beta.1/SHA256SUMS) from the [public beta page](https://github.com/nope-gao/KeyTrace/releases/tag/v0.4.2-beta.1); verify using the command below. GitHub’s automatic Source code ZIP is not the app. Unzip and move **KeyTrace.app** to `~/Applications` before opening it.

```bash
# In the folder containing the downloaded ZIP and SHA256SUMS
awk '$2 == "KeyTrace-arm64.zip"' SHA256SUMS | shasum -a 256 -c -
```

Terminal installation explicitly selects this Pre-release, never `/latest`:

```bash
curl -fsSL https://raw.githubusercontent.com/nope-gao/KeyTrace/v0.4.2-beta.1/install.sh -o /tmp/keytrace-install.sh
bash /tmp/keytrace-install.sh --version v0.4.2-beta.1
```

The installer checks SHA-256, app version and signing compatibility without sudo. It stops while the app is running, leaves identical installations untouched, and refuses incompatible signature changes before replacement. To migrate, quit and back up the old app, replace it manually and authorize again. Recordings remain in place.

If macOS blocks first launch, review the source and use **System Settings → Privacy & Security → Open Anyway** for this app only. Do not disable Gatekeeper, SIP or system-wide protections. If your Mac or organization disallows an exception, stop installation.

In **Privacy & Security → Input Monitoring**, add KeyTrace from its actual installed location, enable it, then quit and reopen. Choose Resume if paused. Press keys and click the mouse; confirm the latest recording time and both counters increase. An enabled switch alone is not proof. After an update, if the switch is on but recording fails: quit, remove the old entry and add the new app. If needed, run the app-scoped reset below, then authorize manually.

```bash
tccutil reset ListenEvent app.keytrace.mac
```

KeyTrace uses a separate data directory and does not automatically import recordings from other apps. Enable Input Monitoring separately on first installation.

## Interface language

The initial setting is **Follow system**. The app checks the ordered macOS preferred-language list and selects a supported match. Available languages: **简体中文, 繁體中文, English, 日本語, Español, Français, Deutsch**. English is used if none of your preferred languages are supported. Choose a language or return to Follow system at the bottom of the window; the preference is saved.

The interface, menus, existing status messages, dates and numbers, mouse labels, function-key names, and video captions follow the selected language. Letter keys retain the physical ANSI layout. Videos keep the language selected when the export starts; manual switching is disabled during export. macOS controls the language of its own permission dialogs and underlying system error details.

## Video sound

Choose **Keyboard taps** (default), **Mechanical**, **Soft taps**, or **Silent**. Each physical key has a distinct, deterministic short timbre, triggered only on key down and aligned to the first animation frame showing the press. Dense presses overlap at higher speeds. Excluding the mouse also excludes its click sounds. The five-second outro remains quiet.

Audio is synthesized locally. It does not use the microphone, record your real keyboard, or depend on external sound assets. Sound-enabled videos contain a 48 kHz AAC track; Silent exports have no audio track.

## Build from source

```bash
xcode-select --install
bash build.sh
```

Local builds use ad-hoc signing; replacing an installed app may require authorization again.

## Usage

Choose the time range, speed, mouse option, and heatmap mode, then click **Export to Downloads**. Activity from periods without recordings cannot be recovered.

## Local data and privacy

Data is stored in `~/Library/Application Support/KeyTrace/`. The app does not upload it or include telemetry. The installer accesses GitHub to download releases.

Animated playback requires press/release timestamps, physical key identifiers, device information, and event order. The app also stores application names, bundle IDs, and usage-duration statistics. It does not read final text produced by an input method, window titles, web addresses, or mouse coordinates. **Key identifiers and their sequence may still reveal what was typed. Recordings are sensitive data; do not publicly upload the data directory.**

Pause stops new presses and usage-duration statistics but keeps history. Data is local plaintext with no automatic expiration. Quit before moving data, export caches, and unwanted videos to Trash.

`~/Library/Application Support/KeyTrace/` · `~/Library/Caches/KeyTrace/VideoJobs/` · `~/Downloads/KeyTrace-*.mp4`

## Known limitations

- Primarily supports ANSI layouts. ISO/JIS layouts are not fully supported; automatic detection may not cover every third-party device.
- Fn keys, media keys, and secure input may not be fully recorded. Touch ID is not an ordinary recorded key press.
- Device attribution may be limited when multiple keyboards are used. Holding a key does not count automatic repeats as separate presses.
- Videos use SceneKit, Metal, and AVFoundation directly; Blender is not required.

# MinisThinkingRules

Standalone Theos tweak, package `com.knight914.ministhinkingrules`, version `0.0.2`. Targets `com.aztut.app` with marketing version `1.14` or `1.14.0`, on iOS 16+ (arm64/arm64e), with a compatible tweak loader enabled for Minis. No device installation has been performed.

## Use after a separately authorized installation

1. Run `minis-config get thinkingrules` in the Minis Linux terminal and manually copy the complete JSON response. If the command reports an error or permission denial, there is nothing to import; the tweak does not bypass that restriction.
2. On the foreground Minis main screen, close any modal, then double-tap with three fingers. The tweak uses public UIKit window notifications and a gesture recognizer; it does not add a row to Minis Settings. Accessibility gestures or other recognizers may conflict. Done closes the viewer.
3. Paste into the text field using the system paste action. Tap **Import Snapshot**. The viewer accepts `{ "ok": true, "value": "[...]" }` or the decoded provider array itself, up to 512 KiB of UTF-8 input. An invalid import replaces the results with a diagnostic. Successful import clears the input field.
4. The viewer lists provider names and IDs, custom rules in exported priority order, and built-in fallbacks separately. Rule details show the imported JSON (including wire format and reasoning echo when present). An upstream `editable` flag is metadata only; nothing in this viewer is editable. Paste a new export to refresh.

## Source and limits

OpenMinis tag [`1.14`](https://github.com/OpenMinis/OpenMinis/tree/1.14) resolves to `b4c0661d5631ebab4d1a2e6f3fd4c805d4030a6c`. The iOS `src/ios/Shared/Config/ConfigRegistry+Builtins.swift` registers the aggregate `thinkingrules` as a `ReadOnlyField`; it skips providers with neither custom nor applicable built-in rules. `src/ios/Shared/Config/Collections/ThinkingRulesCollection.swift` defines custom child paths, first-match ordering and built-in restrictions. The registry/store/cache are app-internal Swift implementation, not a verified callable plugin ABI. The presence of native source does not establish an external native entry point in the installed app.

The explicit paste fallback reads a user-supplied snapshot, not live state. No shell spawning from UIKit, private symbols/offsets, app database or container reads, network transport, automatic clipboard reads, disk persistence by the tweak, or config writes. Data is only held in the viewer while open; the system clipboard is separate and is not cleared. Copied data may contain provider identifiers and custom labels. The renderer does not resolve actual model matches or imply that a stale or filtered export reflects current settings.

## Tests and CI

Linux (Python 3 + PyYAML):

```sh
python3 tests/check_project.py
minis-config get thinkingrules | python3 tests/check_project.py --live
```

The live check validates the contract without logging the snapshot; it does not execute Objective-C. `tests/SnapshotTests.m` runs the actual Foundation parser and renderer on macOS in CI (raw/enveloped JSON, ordering, empty, malformed, oversized). A future authorized device smoke test should verify launch/version gating, gesture open/close, valid/invalid/empty paste, repeat import, and foreground/multiwindow behavior. None of those UIKit cases have been device-tested.

`.github/workflows/build.yml` defines a `macos-15` matrix for official Theos `rootless` (`iphoneos-arm64`) and official roothide Theos `roothide` (`iphoneos-arm64e`), with pinned toolchain and patched iPhoneOS 16.5 SDK revisions. Both target arm64/arm64e, run native parser tests, verify deb metadata and upload distinct artifacts. CI only triggers on `work/**` pushes. See GitHub Actions for build status and artifacts. An actual authorized build must verify compiler/SDK compatibility and loader behavior; package schemes alone do not prove runtime support.

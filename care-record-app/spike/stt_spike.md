# Task 2 — On-device STT spike

Status: **code complete, awaiting real-device run.** This spike has NOT been run on a
physical phone yet — nothing below the "Device run" section is filled in. Do not treat
this as a GO or NO-GO until Tom runs it and records the evidence.

## Scope change vs. the original brief

The original task brief (`.superpowers/sdd/task-2-brief.md`) asked to (1) bundle a ggml
model as a committed asset and (2) read aloud a script containing a real patient's
caregiving note. Both were overridden for this spike:

1. **No model committed to git.** This repo is pushed to public GitHub, which rejects
   files >100MB; a ggml model is 140–490MB. The model is downloaded once at runtime
   instead (see below). Production app will bundle it later — that's a separate,
   deliberate decision, not this spike's job.
2. **No real patient/caregiving text.** The on-screen read-aloud script is a synthetic
   sentence with no real clinical content:
   > 今天精神穩定，午餐吃一半，下午走一走，晚上睡得好，情緒平穩。

## Step 1 — Chosen binding: `sherpa_onnx` (was `whisper_ggml`, swapped 2026-07-23)

`whisper_ggml ^1.3.0` was evaluated first and initially chosen (see git history for
that writeup), but it transitively pulls `ffmpeg_kit_flutter_new` →
`com.arthenica.ffmpegkit:flutter:7.0`, and that AAR's resource transform fails on this
project's (older) Android Gradle Plugin toolchain — see the BLOCKER section below,
kept for the record. `ffmpeg-kit-flutter` was retired by its author in 2025 (no more
releases), and this toolchain predates the AGP version needed to process its AAR
correctly. Every `whisper_ggml` version usable under this project's Dart `^3.6.0`
pin (i.e. `<1.4.0`) carries that same broken dependency, so no `whisper_ggml` version
downgrade could fix it — the binding itself had to change.

Re-evaluated against pub.dev on 2026-07-23:

| Package | Latest on pub.dev | Resolves under Dart 3.6.0? | ffmpeg-kit dependency? |
|---|---|---|---|
| `whisper_ggml` | 2.4.0 | Only `1.3.0` (needs `ffi>=2.1.4` → Dart 3.7+ above that) | **Yes** (blocks Android build) |
| `whisper_flutter_plus` | 1.0.0 (2023-09-04, unmaintained ~3 yrs) | yes | not evaluated further — ruled out on maintenance grounds |
| `sherpa_onnx` | 1.13.4 | **Yes** — `environment: sdk: '>=3.1.0 <4.0.0'`, `ffi: ^2.1.0` resolves to `ffi 2.1.3` (compatible with Dart 3.6.0) | **No** |

**Chose `sherpa_onnx` ^1.13.4.** Reasons:
- Confirmed zero `ffmpeg-kit` anywhere in the resolved tree: `grep -i ffmpeg
  pubspec.lock` returns nothing after the swap, and none of the platform packages'
  `android/build.gradle` (`sherpa_onnx_android_arm64/armeabi/x86/x86_64`, all 1.13.4)
  reference `ffmpeg` — checked all four files directly.
- Officially supports offline Whisper models via `OfflineWhisperModelConfig` /
  `OfflineRecognizer` (`k2-fsa/sherpa-onnx`, the ONNX port of whisper.cpp's model
  family), plus SenseVoice, Paraformer, and others — Whisper was picked to stay
  closest to the original brief's "whisper.cpp" intent.
- Runs fully offline once model files are on disk (no network at inference).
- `OfflineWhisperModelConfig.language` accepts `'zh'`, `.task` accepts `'transcribe'`.
- Actively maintained (1.13.4, regularly released; broad platform coverage: Android,
  iOS, macOS, Linux, Windows).
- `flutter pub remove whisper_ggml && flutter pub add sherpa_onnx` resolved cleanly
  under the project's unchanged `environment: sdk: ^3.6.0` — no SDK bump needed, per
  the hard constraint not to touch Flutter/Dart.

**Trade-off vs. `whisper_ggml`:** `sherpa_onnx`'s Whisper support needs **three**
separate files (`encoder.onnx`, `decoder.onnx`, `tokens.txt`) instead of
`whisper_ggml`'s single `.bin`, and the API is lower-level (manual
`OfflineRecognizer` → `OfflineStream` → `acceptWaveform` → `decode` → `getResult`
instead of one `transcribe()` call). Both are handled in
`lib/spike/stt_spike_screen.dart` (three-file download step; thin wrapper around the
stream API) — neither is a blocker, just more code than the old binding needed.

## Step 2 (adapted) — Model fetched at runtime, not bundled

Instead of committing an asset, the spike downloads three files (Whisper needs a
separate encoder, decoder, and token vocab — unlike `whisper_ggml`'s single `.bin`)
on first launch, from an **unpacked** Hugging Face mirror of the official
`k2-fsa/sherpa-onnx` release (the official GitHub release only ships a combined
`.tar.bz2`, and this project has no tar/bzip2-extraction dependency to unpack it —
downloading the three files individually avoids adding one):

```
https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base/resolve/main/base-encoder.int8.onnx
https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base/resolve/main/base-decoder.int8.onnx
https://huggingface.co/csukuangfj/sherpa-onnx-whisper-base/resolve/main/base-tokens.txt
```

Downloaded (via `dart:io HttpClient`, no new HTTP package dependency) into
`getApplicationSupportDirectory()/whisper_base/`, each to a `.part` temp name first
then renamed on success — so a crash mid-download can't leave a truncated file that
looks cached on the next launch. `_downloadIfMissing()` skips any file that already
exists with `length > 0`.

**Measured file size (via `curl -sIL` HEAD request, following the HF CDN redirect,
2026-07-23):**

| File | Content-Length |
|---|---|
| `base-encoder.int8.onnx` | 29,120,534 bytes (~27.8 MB) |
| `base-decoder.int8.onnx` | 130,672,026 bytes (~124.6 MB) |
| `base-tokens.txt` | 816,730 bytes (~0.8 MB) |
| **Total** | **160,609,290 bytes (~153 MB)** ← chosen (`whisper-base`, int8) |

For reference, `whisper-tiny` (int8) totals ~104 MB but has noticeably worse Chinese
accuracy; `whisper-small` (int8, per the same HF layout) would total roughly ~250 MB.
`base` was picked as the closest available match to the production spec's "small
quantised model, ~180MB" figure while keeping Chinese transcription quality
reasonable — a production follow-up should re-run this A/B on a real device before
locking in a tier.

**On-screen download UX:** the spike screen shows a spinner + status text
("正在下載語音模型（whisper-base，約 160MB，僅需一次，建議使用 Wi-Fi）…") while the
three files are downloading. No byte-level progress bar (same limitation as before,
now because a hand-rolled `HttpClient` download loop doesn't wire one up either) —
spinner + descriptive text only.

## Step 3 — Spike screen

`lib/spike/stt_spike_screen.dart`, wired as the app's `home` in `lib/main.dart`
(temporarily replacing the placeholder screen — revert once the gate is decided).

Screen contents:
- The synthetic script, shown large (26px, `#222` on white card, matches the app's
  low-vision contrast rule from `CLAUDE.md`).
- Model-download status (spinner while downloading, checkmark when ready, retry
  button on error).
- A big 🎤 開始錄音 / ⏹ 停止錄音 button (disabled while transcribing).
- Recording captures 16kHz mono WAV via the `record` package
  (`RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1)`) to a
  temp file (`path_provider`'s `getTemporaryDirectory()`).
- On stop: `sherpa_onnx.readWave(path)` → `OfflineRecognizer.createStream()` →
  `stream.acceptWaveform(samples:, sampleRate:)` → `recognizer.decode(stream)` →
  `recognizer.getResult(stream).text`, with `OfflineWhisperModelConfig(language: 'zh',
  task: 'transcribe')` set when the recognizer is built (right after the model
  download finishes, once per app run).
- While that's running: 辨識中… spinner.
- Result: raw transcription text in a `SelectableText`, plus wall-clock milliseconds
  measured around the `readWave` → `decode` → `getResult` sequence.

Android manifest (`android/app/src/main/AndroidManifest.xml`) gained two permissions:
`RECORD_AUDIO` (mic capture) and `INTERNET` (one-time model download).

## What was verified WITHOUT a device

- `flutter analyze`: **clean, 0 issues** (re-verified 2026-07-23 after the
  `sherpa_onnx` swap).
- `flutter build apk --debug`: **PASSES** (re-verified 2026-07-23 after the
  `sherpa_onnx` swap — see `../../.superpowers/sdd/task-2-report.md` for the exact
  `✓ Built ...` line, apk path, and size). The app now actually builds and installs
  on Android; the BLOCKER below is historical (kept for the record, not current
  status).
- Actual transcription accuracy/speed was **not** and **cannot** be tested here — no
  physical device or emulator with a working microphone + native ONNX runtime library
  was exercised. Everything below this line is empty until Tom runs it on a real phone.

---

## Device run (Tom to fill)

- **Device model:**
- **OS version:**
- **Wi-Fi network / model download time:**
- **Transcription wall-clock time (from the on-screen "耗時" readout):**
- **Raw transcription output (paste exactly what the screen showed):**
- **Keyword check** — does the output preserve the synthetic script's content?
  (精神穩定 / 午餐吃一半 / 下午走一走 / 晚上睡得好 / 情緒平穩)
- **GO / NO-GO:**
  - GO if the sentence's meaning/keywords come through correctly (minor filler-word
    errors OK) AND transcription finishes in a tolerable time (target < ~15s) on a
    mid-range phone.
  - NO-GO if the output is mangled or unusably slow. Stop before Task 3; escalate to
    Tom with this evidence — options are a larger model, a different binding, or
    revisiting the input method.

---

## ✅ RESOLVED — binding swapped to `sherpa_onnx` (2026-07-23)

**Historical record of the original blocker** (kept so future-me doesn't rediscover
the same trap): `flutter build apk --debug` with `whisper_ggml ^1.3.0` FAILED with

```
Execution failed for task ':app:processDebugResources'.
> Failed to transform flutter-7.0.aar (com.arthenica.ffmpegkit:flutter:7.0) ...
  > Execution failed for AarResourcesCompilerTransform: .../jetified-flutter-7.0/AndroidManifest.xml
```

Root-cause chain:
- This environment's Flutter is **3.27.0 / Dart 3.6.0 (Dec 2024, ~1.5 years old)**.
- Dart 3.6 caps `whisper_ggml` at **1.3.0** (>=1.4.0 needs Dart 3.7+).
- `whisper_ggml 1.3.0` pulls `ffmpeg_kit_flutter_*`, whose bundled `com.arthenica.ffmpegkit:flutter:7.0`
  AAR will not pass this (old) Android Gradle Plugin's resource transform.
- Net: the chosen STT binding would not build for Android on this toolchain.

**Resolution:** swapped the binding to `sherpa_onnx ^1.13.4` (see Step 1 above for
the full evaluation). It has zero `ffmpeg-kit` anywhere in its dependency tree and
resolves cleanly under the unchanged Dart `^3.6.0` pin — no Flutter/Dart SDK upgrade
needed, honoring the hard constraint not to touch the shared SDK.
`flutter build apk --debug` now **succeeds** (see
`../../.superpowers/sdd/task-2-report.md` for the exact build output line, apk path,
and size). minSdk stays raised to 24 (still required by `record` + `sherpa_onnx`'s
native plugins).

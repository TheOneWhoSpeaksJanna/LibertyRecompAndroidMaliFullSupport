# Mali fork: crash and audio investigation

This fork targets improved Mali compatibility without regressing Adreno devices.
No native crash fix or audio fix has been verified yet.

## Baseline case (reported 2026-10-14)

- Device: Xiaomi 24116RACCG (Redmi Note 14 Pro 4G), MT6789.
- GPU: Mali-G57 MC2, ARM system Vulkan 1.3 driver r54p1.
- Android: 16, API 36; ABI arm64-v8a; page size 4096.
- Original app: 0.5.9.3 (18).
- Exit: signal 11 (SIGSEGV) at approximately 14:36:14 local time.
- Repeated audio warning: `audio: 822 of 1875 blocks were silence (no guest frame ready), 4 queued`. This reports 43.8% silence in that interval.
- In the seconds preceding the exit, the runtime logged repeated `gta4-native-virtual-resource: point=unlock` and shader pipeline details. Temporal proximity does **not** establish cause.
- No crashing thread, fault address or symbolized tombstone stack was supplied. The reason for SIGSEGV is **unknown**.

## First tests

1. Back up `Android/data/com.libertyrecomp/files/args.txt` and all game saves.
2. Reproduce once with *stock* upstream settings and the system Vulkan driver. Record the scene, frame rate and approximate time to failure.
3. Test `os/android/android_args/mali_g57_test.txt` separately, preferably one setting at a time. This changes the render workload and increases the audio queue from 32 to 48 blocks. It cannot repair missing guest audio production.
4. Capture `Android/data/com.libertyrecomp/files/crash_reports/` including the original `.tombstone.pb`, `debug_logs/`, `Liberty Recompiled/logs/`, `last_launch.txt` and `args.txt`.
5. Build the debug APK **with unstripped native libraries** using `android-apk.yml`; use `os/android/scripts/symbolize.sh` / NDK tools with the same build's libraries. A native tombstone with fault address and stack is needed to isolate SIGSEGV.
6. Compare multiple runs in the same game location (scene, lighting, traffic), record crash counts and audio-silence percentages. Do not infer a fix from one successful run.
7. Keep upstream Adreno behavior unchanged unless a modification is supported by tests on both GPU families.

## What the baseline does not prove

- A memory address of 0 MB at exit is not evidence of out-of-memory: the process is already dead.
- `gta4-native-virtual-resource` diagnostics are not a stack trace.
- Audio underruns and SIGSEGV can be independent issues.
- Higher `audio_maxqframes` can hide short stalls at the cost of latency; it cannot force absent audio frames to be generated.
- Reduced graphics settings may help frame times but do not establish that the Vulkan driver caused the crash.

## Maintaining the fork

The scheduled `upstream-check.yml` reports how many commits arrived upstream.
It deliberately does not force-reset, merge or discard fork changes. Upstream
changes should be reviewed and compiled through `android-apk.yml` before being
merged into `main`.

The Android CI job produces a **debug-signed test APK**, not a stable release.
Installing it over the original APK may fail because of a signature mismatch.
Back up saves and game data before changing installations.

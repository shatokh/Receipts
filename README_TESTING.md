# Integration Testing Guide

This document describes how to run the Flutter integration tests that exercise the end-to-end receipt import flow on an Android emulator and in GitHub Actions.

## Prerequisites

- Flutter SDK (stable channel)
- Android SDK command-line tools (including `avdmanager`, `sdkmanager`, and `emulator`)
- An Android system image: `system-images;android-34;google_apis;x86_64`

## One-time AVD setup

```bash
flutter emulators --create --name it_api34 --device pixel
flutter emulators --launch it_api34
```

If you already have an emulator named `it_api34` you can skip the create step.

## Running the integration tests locally

1. Ensure the emulator is running (for example using the commands above or Android Studio).
2. Run the tests targeting the emulator:

```bash
flutter test integration_test -d emulator-5554
```

### Running on a connected Android device

1. Enable developer options and USB debugging, then connect the device (or pair it through Android Debug Bridge).
2. Identify its exact Flutter device identifier:

```bash
flutter devices
```

3. Run the same synthetic, offline suite against that identifier:

```bash
flutter test integration_test -d <connected-device-id>
```

The helper scripts below create or boot an emulator; use the direct command for an already connected device. Record the device model/API and result in the active Android E2E sub-plan when collecting release evidence.

### Patrol native-system pilot (temporary local runner)

Phase 16 uses Patrol only on the verified `it_api36` / `emulator-5554` image. Run one selected Patrol test through the project helper:

```powershell
.\tool\run_patrol_android.ps1 -DeviceId emulator-5554 -TestTarget patrol_test/document_picker_cancel_test.dart
```

The helper uses `patrol build android` and then invokes the same `PatrolJUnitRunner` through `adb`. This is a host-only workaround for an Android Gradle UTP local mTLS result-listener defect: it does not treat the Gradle HTML/protobuf report as green, and it fails unless the JUnit runner itself reports a successful test. It is manual-only and not part of the PR or coverage gate. Do not use another AVD or a physical device while the Patrol/Maestro comparison is in progress.

### Android E2E launch rules

- For the Phase 16 comparison, use only `it_api36` / `emulator-5554`. Use headless mode for recorded runs; for a visual Patrol demonstration, start the same AVD with a window and `-no-snapshot`:

  ```powershell
  & "$env:ANDROID_SDK_ROOT\emulator\emulator.exe" -avd it_api36 -no-snapshot -no-boot-anim
  ```

- Before starting a test, wait until both commands succeed: `adb -s emulator-5554 get-state` prints `device`, and `adb -s emulator-5554 shell getprop sys.boot_completed` prints `1`. Do not treat a serial listed by `adb devices` as ready by itself.
- `default_boot` snapshot failures, early `device offline` messages, and `UpdateCheck` TLS failures are non-blocking emulator-host diagnostics if the readiness check succeeds. They do not justify app changes or committed TLS bypasses.
- If Android dependencies cannot be downloaded because a locally installed TLS interceptor is not trusted, keep the truststore outside Git and pass its path only for the current shell:

  ```powershell
  $env:RECEIPTS_GRADLE_TRUST_STORE = 'C:\local-only\gradle-truststore'
  .\tool\run_patrol_android.ps1
  ```

  The helper validates the path and passes it only to Gradle. Do not commit certificates, truststores, proxy settings, or antivirus exceptions.
- Run `patrol develop` only from an interactive terminal; it needs a TTY for hot restart. It is for observing/repeating UI actions, while `run_patrol_android.ps1` is the deterministic manual result command.

### Helper scripts

- **macOS/Linux**: `./tool/it_android.sh`
- **Windows (PowerShell)**: `./tool/it_android.ps1`

Both scripts will create the AVD if missing, boot a headless emulator, and execute `flutter test integration_test` against it. Environment variables `AVD_NAME` and `DEVICE_ID` can override the defaults.

If the local SDK has a different installed system image, keep the CI default unchanged and pass that image explicitly to the PowerShell helper. For example, the local API 36 Google APIs image can be used as follows:

```powershell
.\tool\it_android.ps1 -AvdName it_api36 -SystemImage 'system-images;android-36;google_apis_playstore;x86_64'
```

## GitHub Actions workflow

The workflow `.github/workflows/integration_test.yml` provisions a headless API 34 emulator using `reactivecircus/android-emulator-runner@v2`. It is intentionally manual-only and runs through `workflow_dispatch` so emulator tests do not block every PR.

When triggered manually, the workflow:

1. Checks out the repository.
2. Installs Java 17 and Flutter 3.35.3 on the stable channel.
3. Restores pub dependencies from cache and runs `flutter pub get`.
4. Boots a headless emulator (API 34, Google APIs, x86_64) with animations disabled.
5. Executes `flutter test integration_test -d emulator-5554`.

The workflow is tuned to keep total duration within ~3–5 minutes once the emulator is available. Fast PR feedback remains in the analyze/unit/build workflows.

## Debugging tips

- Run `flutter devices` to confirm the emulator ID. Update the `-d` flag if your emulator exposes a different ID.
- Use `flutter logs -d <device>` in a separate terminal to stream logs while tests run.
- If database state leaks between runs, delete the `integration_test.db` file from the selected debug device with:
  ```bash
  adb -s <device-id> shell run-as app.receipts rm databases/integration_test.db
  ```
- When editing the integration test, prefer `pumpAndSettleSafe` and `waitForFinder` helpers instead of arbitrary delays.
- For failures in CI, download the workflow logs to inspect the full emulator output.

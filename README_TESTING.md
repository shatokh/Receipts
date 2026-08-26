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

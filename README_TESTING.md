# Integration Testing Guide

This document describes how to run the Flutter integration tests that exercise the end-to-end receipt import flow on an Android emulator and in CI.

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

### Helper scripts

- **macOS/Linux**: `./tool/it_android.sh`
- **Windows (PowerShell)**: `./tool/it_android.ps1`

Both scripts will create the AVD if missing, boot a headless emulator, and execute `flutter test integration_test` against it. Environment variables `AVD_NAME` and `DEVICE_ID` can override the defaults.

## GitHub Actions workflow

The workflow `.github/workflows/integration_test.yml` provisions a headless API 34 emulator using `reactivecircus/android-emulator-runner@v2`. On every push to `main` and pull request the workflow:

1. Checks out the repository.
2. Installs Java 17 and Flutter (stable channel).
3. Restores pub dependencies from cache and runs `flutter pub get`.
4. Boots a headless emulator (API 34, Google APIs, x86_64) with animations disabled.
5. Executes `flutter test integration_test -d emulator-5554`.

The workflow is tuned to keep total duration within ~3–5 minutes.

## Debugging tips

- Run `flutter devices` to confirm the emulator ID. Update the `-d` flag if your emulator exposes a different ID.
- Use `flutter logs -d <device>` in a separate terminal to stream logs while tests run.
- If database state leaks between runs, delete the `integration_test.db` file from the emulator with:
  ```bash
  adb shell rm /data/data/com.example.biedronka_expenses/databases/integration_test.db
  ```
- When editing the integration test, prefer `pumpAndSettleSafe` and `waitForFinder` helpers instead of arbitrary delays.
- For failures in CI, download the workflow logs to inspect the full emulator output.

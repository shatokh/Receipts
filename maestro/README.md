# Maestro Native Android E2E Cookbook

This folder contains the selected Maestro native Android E2E lane. It covers
the safe document-picker cancel flow plus approved synthetic-PDF import,
duplicate, post-import-navigation, and month-isolation flows.

The flows select durable Flutter `Semantics.identifier` values in
`AppTestSemanticsIds`; they never rely on translated visible text or Flutter
`ValueKey` values. Assertions never expose receipt content, file paths, or
URIs.

## Required baseline

- Use only the existing `it_api36` AVD at `emulator-5554` for the current
  manual native-smoke lane.
- Start it fresh with `-no-snapshot`; wait for both `adb get-state` = `device`
  and `sys.boot_completed` = `1` before building or testing.
- Do not run these flows on a physical device, another AVD, CI, or a device
  farm without a separately scoped follow-up and fresh evidence.

## Windows console cookbook

Set the local CLI and privacy opt-out for the current PowerShell session:

```powershell
$env:MAESTRO = "$env:LOCALAPPDATA\MaestroCLI\maestro\bin\maestro.bat"
$env:MAESTRO_CLI_NO_ANALYTICS = '1'
```

Start the verified AVD in a separate terminal (replace the executable path
only if the Android SDK is installed elsewhere):

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\emulator\emulator.exe" -avd it_api36 -no-snapshot -no-window -gpu host
```

Wait for readiness. Do not treat a boot-time `offline` line, a missing
`default_boot` snapshot, or the emulator UpdateCheck TLS warning as a failure
when these two checks succeed:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb -s emulator-5554 get-state
& $adb -s emulator-5554 shell getprop sys.boot_completed
```

Build and install the app. If Android dependency resolution is affected by the
host TLS interceptor, use the ignored local truststore through the environment
variable below; never commit a certificate, truststore, proxy setting, or
security-product exception:

```powershell
  $env:RECEIPTS_GRADLE_TRUST_STORE = 'C:\local-only\gradle-truststore'
$env:GRADLE_OPTS = "-Djavax.net.ssl.trustStore=$env:RECEIPTS_GRADLE_TRUST_STORE -Djavax.net.ssl.trustStorePassword=changeit"
& C:\FlutterSDK\bin\flutter.bat build apk --debug
& $adb -s emulator-5554 install -r build\app\outputs\flutter-apk\app-debug.apk
```

The picker-cancel flow is a retained regression smoke. Run it when changing
the navigation-to-picker boundary:

```powershell
& $env:MAESTRO check-syntax maestro\document_picker_cancel.yaml
& $env:MAESTRO --device emulator-5554 test maestro\document_picker_cancel.yaml
& $env:MAESTRO --device emulator-5554 test maestro\document_picker_cancel.yaml
```

`clearState: true` deliberately resets only the app data on the selected
emulator before each run. It does not wipe the AVD. Keep generated reports,
screenshots, videos, documents, and device data out of Git.

## Approved synthetic PDF flows

Stage the reviewed synthetic fixture under its generic device filename, then
run each real-picker flow twice. The first flow asserts a safe successful
outcome; the second asserts an exact duplicate outcome. Neither flow asserts
fixture contents, receipt fields, paths, or URIs.

```powershell
& $adb -s emulator-5554 push assets\test\receipts\e2e\receipt_a.pdf /sdcard/Download/receipt_a.pdf
& $adb -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/receipt_a.pdf

& $env:MAESTRO check-syntax maestro\receipt_a_import.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_import.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_import.yaml

& $env:MAESTRO check-syntax maestro\receipt_a_duplicate.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_duplicate.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_duplicate.yaml
```

The root-switch coordinate in these two flows is intentionally restricted to
this fixed comparison baseline: `it_api36` at its verified display geometry.
It opens Documents UI's root chooser, which has no stable resource ID in this
system image. Treat a changed picker layout as a scenario-maintenance event,
not as an app regression.

## Post-import navigation flow

`receipt_a_post_import_navigation.yaml` extends the approved first-import
journey. After the safe success state, it opens Receipts and Month and checks
only durable non-empty Semantics outcomes. It never reads receipt fields or
fixture content. It passed twice on the verified headless baseline.

```powershell
& $env:MAESTRO check-syntax maestro\receipt_a_post_import_navigation.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_post_import_navigation.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_post_import_navigation.yaml
```

## Two-fixture month-isolation flow

`receipt_a_b_month_isolation.yaml` imports the two approved synthetic fixtures
through the real picker. It then selects the first two rendered Month options
through ordinal Semantics identifiers and asserts only the safe one-receipt
structural state. It deliberately does not select dates by visible localized
text or inspect any receipt fields.
It passed twice on the verified headless baseline.

Stage both generic device filenames before running it. Keep the device-side
files and media-scanner output out of Git:

```powershell
& $adb -s emulator-5554 push assets\test\receipts\e2e\receipt_a.pdf /sdcard/Download/receipt_a.pdf
& $adb -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/receipt_a.pdf
& $adb -s emulator-5554 push assets\test\receipts\e2e\receipt_b.pdf /sdcard/Download/receipt_b.pdf
& $adb -s emulator-5554 shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Download/receipt_b.pdf

& $env:MAESTRO check-syntax maestro\receipt_a_b_month_isolation.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_b_month_isolation.yaml
& $env:MAESTRO --device emulator-5554 test maestro\receipt_a_b_month_isolation.yaml
```

If a prior interrupted emulator launcher left a QEMU process alive, stop that
specific stale process before starting another AVD instance. Do not run two
instances of `it_api36` concurrently. On this host, an omitted `-gpu host`
in headless mode can trigger an Android System UI ANR before Maestro sees the
Flutter hierarchy; use a visible window only to diagnose that condition.

Param(
    [string]$AvdName = "it_api34",
    [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"
$systemImage = "system-images;android-34;google_apis;x86_64"

function Ensure-Avd {
    if (-not (avdmanager list avd | Select-String "Name: $AvdName")) {
        Write-Host "Creating Android Virtual Device '$AvdName'"
        $create = "no`n" | avdmanager create avd -n $AvdName -k $systemImage -d pixel_6
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to create AVD $AvdName"
        }
    }
}

function Start-Emulator {
    if (adb devices | Select-String $DeviceId) {
        Write-Host "Emulator $DeviceId already running"
        return
    }

    Write-Host "Starting emulator $AvdName"
    $args = "-avd $AvdName -no-window -no-snapshot -no-boot-anim -noaudio -gpu swiftshader_indirect"
    $process = Start-Process emulator -ArgumentList $args -PassThru
    Start-Sleep -Seconds 5

    Write-Host "Waiting for emulator to boot..."
    adb wait-for-device | Out-Null
    do {
        Start-Sleep -Seconds 2
        $boot = (adb shell getprop sys.boot_completed).Trim()
    } until ($boot -eq "1")

    return $process
}

Ensure-Avd
$emulator = Start-Emulator

try {
    Write-Host "Connected devices:"
    flutter devices

    Write-Host "Running integration tests"
    flutter test integration_test -d $DeviceId
}
finally {
    if ($emulator -and -not $emulator.HasExited) {
        Write-Host "Stopping emulator"
        $emulator.CloseMainWindow() | Out-Null
        Start-Sleep -Seconds 2
        if (-not $emulator.HasExited) {
            $emulator.Kill()
        }
    }
}

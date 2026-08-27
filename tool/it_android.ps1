Param(
    [string]$AvdName = "it_api34",
    [string]$DeviceId = "emulator-5554",
    [string]$SystemImage = "system-images;android-34;google_apis;x86_64"
)

$ErrorActionPreference = "Stop"

function Ensure-Avd {
    if (-not (avdmanager list avd | Select-String "Name: $AvdName")) {
        Write-Host "Creating Android Virtual Device '$AvdName'"
        $create = "no`n" | avdmanager create avd -n $AvdName -k $SystemImage -d pixel_6
        if ($LASTEXITCODE -ne 0) {
            throw "Unable to create AVD $AvdName"
        }
    }
}

function Start-Emulator {
    $existingState = (adb -s $DeviceId get-state 2>$null).Trim()
    $existingDevice = adb devices | Select-String "^$DeviceId\s+"
    if ($existingState -eq 'device' -and
        (adb -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim() -eq '1') {
        Write-Host "Emulator $DeviceId already running and ready"
        return
    }

    $process = $null
    if ($existingDevice) {
        Write-Host "Waiting for existing emulator $DeviceId to become ready"
    }
    else {
        Write-Host "Starting emulator $AvdName"
        $args = "-avd $AvdName -no-window -no-snapshot -no-boot-anim -noaudio -gpu swiftshader_indirect"
        $process = Start-Process emulator -ArgumentList $args -WindowStyle Hidden -PassThru
        Start-Sleep -Seconds 5
    }

    Write-Host "Waiting for emulator to boot..."
    $ready = $false
    for ($attempt = 0; $attempt -lt 90; $attempt++) {
        Start-Sleep -Seconds 2
        $state = (adb -s $DeviceId get-state 2>$null).Trim()
        $boot = (adb -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim()
        if ($state -eq 'device' -and $boot -eq '1') {
            $ready = $true
            break
        }
    }

    if (-not $ready) {
        throw "Emulator $DeviceId did not become ready before the timeout"
    }

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

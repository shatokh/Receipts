param(
    [string]$DeviceId = 'emulator-5554',
    [string]$TestTarget = 'patrol_test/document_picker_cancel_test.dart',
    [string]$GradleTrustStorePath = $env:RECEIPTS_GRADLE_TRUST_STORE
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sdkRoot = if ($env:ANDROID_SDK_ROOT) {
    $env:ANDROID_SDK_ROOT
} elseif ($env:ANDROID_HOME) {
    $env:ANDROID_HOME
} else {
    Join-Path $env:LOCALAPPDATA 'Android\Sdk'
}
$adb = Join-Path $sdkRoot 'platform-tools\adb.exe'
$appApk = Join-Path $projectRoot 'build\app\outputs\apk\debug\app-debug.apk'
$testApk = Join-Path $projectRoot 'build\app\outputs\apk\androidTest\debug\app-debug-androidTest.apk'
$runner = 'app.receipts.test/pl.leancode.patrol.PatrolJUnitRunner'

if (-not (Test-Path -LiteralPath $adb)) {
    throw "Android Debug Bridge was not found under ANDROID_SDK_ROOT."
}

$targetPath = Join-Path $projectRoot $TestTarget
if (-not (Test-Path -LiteralPath $targetPath -PathType Leaf)) {
    throw "Patrol test target was not found."
}

$patrol = Get-Command patrol -ErrorAction SilentlyContinue
if ($null -eq $patrol) {
    $pubPatrol = Join-Path $env:LOCALAPPDATA 'Pub\Cache\bin\patrol.bat'
    if (Test-Path -LiteralPath $pubPatrol) {
        $patrol = Get-Item -LiteralPath $pubPatrol
    } else {
        throw 'Patrol CLI was not found on PATH or in the local Dart Pub cache.'
    }
}
$patrolPath = if ($patrol -is [System.Management.Automation.CommandInfo]) {
    $patrol.Source
} else {
    $patrol.FullName
}
$env:PATROL_ANALYTICS_ENABLED = 'false'

if (-not [string]::IsNullOrWhiteSpace($GradleTrustStorePath)) {
    if (-not (Test-Path -LiteralPath $GradleTrustStorePath -PathType Leaf)) {
        throw 'The local Gradle truststore path is unavailable.'
    }

    $trustStoreOptions = "-Djavax.net.ssl.trustStore=$GradleTrustStorePath -Djavax.net.ssl.trustStorePassword=changeit"
    $env:GRADLE_OPTS = "$env:GRADLE_OPTS $trustStoreOptions".Trim()
}

$ready = $false
for ($attempt = 0; $attempt -lt 30; $attempt++) {
    $state = (& $adb -s $DeviceId get-state 2>$null).Trim()
    $bootCompleted = (& $adb -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim()
    if ($state -eq 'device' -and $bootCompleted -eq '1') {
        $ready = $true
        break
    }
    Start-Sleep -Seconds 2
}

if (-not $ready) {
    throw "Android device '$DeviceId' did not become ready before the timeout."
}

Push-Location $projectRoot
try {
    # `patrol test` is affected on this host by AGP/UTP's local TLS result
    # listener. Build with Patrol, then invoke the same Patrol JUnit runner via
    # adb so the JUnit result remains the command's source of truth.
    & $patrolPath build android --generate-bundle --target $TestTarget
    if ($LASTEXITCODE -ne 0) {
        throw 'Patrol Android build failed.'
    }

    if (-not (Test-Path -LiteralPath $appApk) -or -not (Test-Path -LiteralPath $testApk)) {
        throw 'Patrol Android build did not produce both APK artifacts.'
    }

    & $adb -s $DeviceId install -r $appApk
    if ($LASTEXITCODE -ne 0) {
        throw 'Installing the Patrol app APK failed.'
    }

    & $adb -s $DeviceId install -r $testApk
    if ($LASTEXITCODE -ne 0) {
        throw 'Installing the Patrol test APK failed.'
    }

    $instrumentationOutput = & $adb -s $DeviceId shell am instrument -w -e clearPackageData true $runner 2>&1
    $instrumentationExitCode = $LASTEXITCODE
    $instrumentationOutput | Write-Output
    $instrumentationText = $instrumentationOutput -join [Environment]::NewLine

    if ($instrumentationExitCode -ne 0 -or
        $instrumentationText -match 'FAILURES!!!|INSTRUMENTATION_FAILED|Process crashed' -or
        $instrumentationText -notmatch 'OK \(\d+ test') {
        throw 'Patrol JUnit runner reported a failed or incomplete test run.'
    }
} finally {
    Pop-Location
}

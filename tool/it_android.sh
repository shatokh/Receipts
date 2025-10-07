#!/usr/bin/env bash
set -euo pipefail

AVD_NAME=${AVD_NAME:-it_api34}
DEVICE_ID=${DEVICE_ID:-emulator-5554}
SYSTEM_IMAGE="system-images;android-34;google_apis;x86_64"

function ensure_avd() {
  if ! avdmanager list avd | grep -q "Name: $AVD_NAME"; then
    echo "Creating Android Virtual Device '$AVD_NAME'"
    yes | avdmanager create avd -n "$AVD_NAME" -k "$SYSTEM_IMAGE" --device "pixel_6" || true
  fi
}

function start_emulator() {
  if adb devices | grep -q "$DEVICE_ID"; then
    echo "Emulator $DEVICE_ID already running"
    return
  fi

  echo "Starting emulator $AVD_NAME"
  nohup emulator \
    -avd "$AVD_NAME" \
    -no-window \
    -no-snapshot \
    -no-boot-anim \
    -noaudio \
    -gpu swiftshader_indirect \
    -netfast \
    >/dev/null 2>&1 &

  EMULATOR_PID=$!
  trap 'kill $EMULATOR_PID || true' EXIT

  echo "Waiting for emulator to boot..."
  adb wait-for-device
  boot_completed=""
  until [[ "$boot_completed" == "1" ]]; do
    sleep 2
    boot_completed=$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')
  done
  echo "Emulator ready"
}

ensure_avd
start_emulator

echo "Connected devices:"
flutter devices

echo "Running integration tests"
flutter test integration_test -d "$DEVICE_ID"

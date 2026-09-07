#!/usr/bin/env bash
set -uo pipefail

mkdir -p android_diagnostics
flutter --version > android_diagnostics/flutter-version.txt 2>&1
flutter devices > android_diagnostics/devices.txt 2>&1
adb -s emulator-5554 logcat -c || true
timeout 20m flutter --verbose test integration_test/task_test.dart \
  -d emulator-5554 --machine \
  > android_test_results.json 2> android_test_verbose.log
test_exit_code=$?
cat android_test_results.json
cat android_test_verbose.log >&2
printf '%s\n' "$test_exit_code" > android_diagnostics/exit-code.txt
adb -s emulator-5554 logcat -d -v threadtime > android_diagnostics/logcat.txt 2>&1 || true
if [ "$test_exit_code" -ne 0 ]; then
  adb -s emulator-5554 exec-out screencap -p > android_diagnostics/failure.png || true
fi
exit "$test_exit_code"

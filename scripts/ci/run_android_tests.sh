#!/usr/bin/env bash
set -euo pipefail

mkdir -p android_diagnostics
credentials_file="${RUNNER_TEMP:-.}/demo-login-credentials.json"
trap 'rm -f "$credentials_file"' EXIT
python3 scripts/ci/create_demo_credentials.py "$credentials_file"
flutter --version > android_diagnostics/flutter-version.txt 2>&1
flutter devices > android_diagnostics/devices.txt 2>&1
adb -s emulator-5554 logcat -c || true
set +e
timeout 20m flutter --verbose test integration_test/task_test.dart \
  -d emulator-5554 --machine --dart-define-from-file="$credentials_file" \
  2> >(tee android_test_verbose.log >&2) \
  | tee android_test_results.json \
  | python3 scripts/ci/capture_failure_screenshots.py \
      android emulator-5554 android_diagnostics/failure-screenshots
test_exit_code=${PIPESTATUS[0]}
set -e
cat android_test_results.json
cat android_test_verbose.log >&2
printf '%s\n' "$test_exit_code" > android_diagnostics/exit-code.txt
adb -s emulator-5554 logcat -d -v threadtime > android_diagnostics/logcat.txt 2>&1 || true
if [ "$test_exit_code" -ne 0 ]; then
  # Fallback for crashes and timeouts that bypass the per-test failure wrapper.
  adb -s emulator-5554 exec-out screencap -p > android_diagnostics/failure.png || true
fi
exit "$test_exit_code"
